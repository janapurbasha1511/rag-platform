resource "docker_container" "redis" {
  name  = "rag-redis"
  image = var.redis_image

  networks_advanced {
    name = docker_network.rag_network.name
  }

  volumes {
    volume_name    = docker_volume.redis_data.name
    container_path = "/data"
  }

  command = ["redis-server", "--appendonly", "yes"]

  ports {
    internal = 6379
    external = var.redis_port
  }

  restart = "unless-stopped"
}