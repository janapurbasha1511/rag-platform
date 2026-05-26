variable "fastapi_port" {
  default = 8000
}

resource "docker_image" "fastapi" {
  name = "rag-fastapi:latest"
  build {
    context = "/home/khokan/rag-platform/app"
  }
}

resource "docker_container" "fastapi" {
  name  = "rag-fastapi"
  image = docker_image.fastapi.image_id

  networks_advanced {
    name = docker_network.rag_network.name
  }

  ports {
    internal = 8000
    external = var.fastapi_port
  }

  env = [
    "MILVUS_HOST=milvus-standalone",
    "MILVUS_PORT=19530",
    "REDIS_HOST=rag-redis",
    "REDIS_PORT=6379",
    "VLLM_BASE_URL=http://rag-vllm:8000/v1"
  ]

  depends_on = [
    docker_container.milvus,
    docker_container.redis,
    docker_container.vllm
  ]

  restart = "unless-stopped"
}