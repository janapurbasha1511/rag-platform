variable "milvus_image" {
  default = "milvusdb/milvus:v2.4.0"
}

variable "etcd_image" {
  default = "quay.io/coreos/etcd:v3.5.5"
}
variable "minio_image" {
  default = "minio/minio:latest"
}

variable "redis_image" {
  default = "redis:7.2"
}

variable "attu_image" {
  default = "zilliz/attu:v2.4"
}

variable "network_name" {
  default = "rag-network"
}

variable "milvus_port" {
  default = 19530
}

variable "milvus_http_port" {
  default = 9091
}

variable "redis_port" {
  default = 6379
}

variable "attu_port" {
  default = 8080
}

variable "minio_port" {
  default = 9000
}

variable "minio_console_port" {
  default = 9001
}
variable "wsl_username" {
  default = "khokan"
}