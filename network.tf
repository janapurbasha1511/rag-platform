resource "docker_network" "rag_network" {
  name = var.network_name

  driver = "bridge"

  ipam_config {
    subnet  = "172.20.0.0/16"
    gateway = "172.20.0.1"
  }
}