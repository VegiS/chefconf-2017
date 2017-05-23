job "nginx-lb" {
  datacenters = ["dc1"]
  type        = "system"

  priority = 75

  task "server" {
    driver = "docker"

    config {
      image        = "sethvargo/nginx-lb"
      network_mode = "host"

      args = [
        "--peer=hab-sup.service.consul",
        "--bind=backend:http-echo.default",
        "--listen-http=${NOMAD_ADDR_hab_http}",
        "--listen-gossip=${NOMAD_ADDR_hab_gossip}",
      ]
    }

    resources {
      cpu    = 100 # MHz
      memory = 512 # MB

      network {
        mbits = 100

        port "http" {
          static = "80"
        }

        port "hab_http"{}
        port "hab_gossip"{}
      }
    }

    logs {
      max_files     = 1
      max_file_size = 2
    }
  }
}
