output "milvus_grpc_endpoint" {
  value = "localhost:${var.milvus_port}"
}

output "milvus_http_endpoint" {
  value = "localhost:${var.milvus_http_port}"
}

output "redis_endpoint" {
  value = "localhost:${var.redis_port}"
}

output "attu_ui" {
  value = "http://localhost:${var.attu_port}"
}

output "minio_console" {
  value = "http://localhost:${var.minio_console_port}"
}
output "fastapi_endpoint" {
  value = "http://localhost:${var.fastapi_port}"
}

output "vllm_endpoint" {
  value = "http://localhost:${var.vllm_port}"
}