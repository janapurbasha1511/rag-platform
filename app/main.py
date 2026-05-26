import os
import uuid
import httpx
import redis

from fastapi import FastAPI, UploadFile, File
from fastapi.responses import JSONResponse
from pymilvus import connections, Collection, CollectionSchema, FieldSchema, DataType, utility
from sentence_transformers import SentenceTransformer
from pdfminer.high_level import extract_text as extract_pdf_text
import io

app = FastAPI()

MILVUS_HOST = os.getenv("MILVUS_HOST", "localhost")
MILVUS_PORT = os.getenv("MILVUS_PORT", "19530")
REDIS_HOST = os.getenv("REDIS_HOST", "localhost")
REDIS_PORT = int(os.getenv("REDIS_PORT", "6379"))
VLLM_BASE_URL = os.getenv("VLLM_BASE_URL", "http://localhost:8001/v1")

COLLECTION_NAME = "rag_documents"
EMBEDDING_DIM = 384
CHUNK_SIZE = 500
CHUNK_OVERLAP = 50

embedding_model = SentenceTransformer("all-MiniLM-L6-v2")
redis_client = redis.Redis(host=REDIS_HOST, port=REDIS_PORT, decode_responses=True)


def connect_milvus():
    connections.connect("default", host=MILVUS_HOST, port=MILVUS_PORT)


def get_or_create_collection():
    connect_milvus()
    if utility.has_collection(COLLECTION_NAME):
        return Collection(COLLECTION_NAME)

    fields = [
        FieldSchema(name="id", dtype=DataType.VARCHAR, is_primary=True, max_length=64),
        FieldSchema(name="text", dtype=DataType.VARCHAR, max_length=4096),
        FieldSchema(name="source", dtype=DataType.VARCHAR, max_length=256),
        FieldSchema(name="embedding", dtype=DataType.FLOAT_VECTOR, dim=EMBEDDING_DIM),
    ]
    schema = CollectionSchema(fields=fields, description="RAG document chunks")
    collection = Collection(name=COLLECTION_NAME, schema=schema)

    index_params = {
        "index_type": "HNSW",
        "metric_type": "COSINE",
        "params": {"M": 16, "efConstruction": 200},
    }
    collection.create_index(field_name="embedding", index_params=index_params)
    return collection


def chunk_text(text: str):
    words = text.split()
    chunks = []
    start = 0
    while start < len(words):
        end = start + CHUNK_SIZE
        chunk = " ".join(words[start:end])
        chunks.append(chunk)
        start += CHUNK_SIZE - CHUNK_OVERLAP
    return chunks


@app.on_event("startup")
def startup():
    get_or_create_collection()


@app.post("/upload")
async def upload_document(file: UploadFile = File(...)):
    content = await file.read()
    filename = file.filename

    if filename.endswith(".pdf"):
        text = extract_pdf_text(io.BytesIO(content))
    else:
        text = content.decode("utf-8", errors="ignore")

    chunks = chunk_text(text)
    embeddings = embedding_model.encode(chunks).tolist()

    collection = get_or_create_collection()

    ids = [str(uuid.uuid4()) for _ in chunks]
    sources = [filename] * len(chunks)

    collection.insert([ids, chunks, sources, embeddings])
    collection.flush()
    collection.load()

    return JSONResponse({"message": f"Uploaded and indexed {len(chunks)} chunks from {filename}"})


@app.post("/query")
async def query(request: dict):
    question = request.get("question", "")
    top_k = request.get("top_k", 5)

    cached = redis_client.get(question)
    if cached:
        return JSONResponse({"answer": cached, "source": "cache"})

    query_embedding = embedding_model.encode([question]).tolist()

    collection = get_or_create_collection()
    collection.load()

    search_params = {"metric_type": "COSINE", "params": {"ef": 100}}
    results = collection.search(
        data=query_embedding,
        anns_field="embedding",
        param=search_params,
        limit=top_k,
        output_fields=["text", "source"],
    )

    retrieved_chunks = [hit.entity.get("text") for hit in results[0]]
    context = "\n\n".join(retrieved_chunks)

    prompt = f"""You are a helpful assistant. Answer the question based only on the context below.

Context:
{context}

Question: {question}

Answer:"""

    async with httpx.AsyncClient(timeout=120) as client:
        response = await client.post(
            f"{VLLM_BASE_URL}/chat/completions",
            json={
                "model": "/models/tinyllama",
                "messages": [{"role": "user", "content": prompt}],
                "max_tokens": 512,
                "temperature": 0.2,
            },
        )
        result = response.json()
        answer = result["choices"][0]["message"]["content"]

    redis_client.setex(question, 3600, answer)

    return JSONResponse({"answer": answer, "source": "llm", "chunks_used": len(retrieved_chunks)})


@app.get("/health")
def health():
    return {"status": "ok"}