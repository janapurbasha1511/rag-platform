variable "vllm_port" {
  default = 8001
}

resource "docker_container" "vllm" {
  name    = "rag-vllm"
  image   = "vllm/vllm-openai:latest"
  runtime = "nvidia"

  networks_advanced {
    name = docker_network.rag_network.name
  }

  volumes {
    host_path      = "/home/khokan/rag-platform/models/tinyllama"
    container_path = "/models/tinyllama"
  }

  ports {
    internal = 8000
    external = var.vllm_port
  }

  command = [
    "--model", "/models/tinyllama",
    "--host", "0.0.0.0",
    "--port", "8000",
    "--gpu-memory-utilization", "0.5",
    "--max-model-len", "2048",
    "--dtype", "float16"
  ]

  env = [
    "NVIDIA_VISIBLE_DEVICES=all",
    "NVIDIA_DRIVER_CAPABILITIES=compute,utility"
  ]

  restart = "unless-stopped"
}