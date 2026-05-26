resource "docker_container" "attu" {
  name  = "milvus-attu"
  image = var.attu_image

  networks_advanced {
    name = docker_network.rag_network.name
  }

  env = [
    "MILVUS_URL=milvus-standalone:19530"
  ]

  ports {
    internal = 3000
    external = var.attu_port
  }

  depends_on = [
    docker_container.milvus
  ]

  restart = "unless-stopped"
}