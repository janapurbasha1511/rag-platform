#etcd cotainer
resource "docker_container" "etcd" {
  name  = "milvus-etcd"
  image = var.etcd_image

  networks_advanced {
    name = docker_network.rag_network.name
  }

  volumes {
    volume_name    = docker_volume.etcd_data.name
    container_path = "/bitnami/etcd"
  }

  env = [
    "ALLOW_NONE_AUTHENTICATION=yes",
    "ETCD_ADVERTISE_CLIENT_URLS=http://milvus-etcd:2379",
    "ETCD_LISTEN_CLIENT_URLS=http://0.0.0.0:2379"
  ]

  restart = "unless-stopped"
}

#minio container 
resource "docker_container" "minio" {
  name  = "milvus-minio"
  image = var.minio_image

  networks_advanced {
    name = docker_network.rag_network.name
  }

  volumes {
    volume_name    = docker_volume.minio_data.name
    container_path = "/data"
  }

  env = [
    "MINIO_ACCESS_KEY=minioadmin",
    "MINIO_SECRET_KEY=minioadmin"
  ]

  command = ["server", "/data", "--console-address", ":9001"]

  ports {
    internal = 9000
    external = var.minio_port
  }

  ports {
    internal = 9001
    external = var.minio_console_port
  }

  restart = "unless-stopped"
}

#milvus standalone container 
resource "docker_container" "milvus" {
  name  = "milvus-standalone"
  image = var.milvus_image

  networks_advanced {
    name = docker_network.rag_network.name
  }

  volumes {
    volume_name    = docker_volume.milvus_data.name
    container_path = "/var/lib/milvus"
  }

  env = [
    "ETCD_ENDPOINTS=milvus-etcd:2379",
    "MINIO_ADDRESS=milvus-minio:9000",
    "MINIO_ACCESS_KEY=minioadmin",
    "MINIO_SECRET_KEY=minioadmin"
  ]

  command = ["milvus", "run", "standalone"]

  ports {
    internal = 19530
    external = var.milvus_port
  }

  ports {
    internal = 9091
    external = var.milvus_http_port
  }

  depends_on = [
    docker_container.etcd,
    docker_container.minio
  ]

  restart = "unless-stopped"
}

