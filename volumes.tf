resource "docker_volume" "etcd_data" {
  name = "etcd_data"
}

resource "docker_volume" "minio_data" {
  name = "minio_data"
}

resource "docker_volume" "milvus_data" {
  name = "milvus_data"
}

resource "docker_volume" "redis_data" {
  name = "redis_data"
}