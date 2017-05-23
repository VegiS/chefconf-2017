job "http-echo" {
  datacenters = ["dc1"]
  type        = "service"

  group "web" {
    count = "3"

    ephemeral_disk {
      size = 10
    }

    task "server" {
      driver = "docker"

      env {
        "HAB_HTTP_ECHO" = "port = ${NOMAD_PORT_http}"
      }

      config {
        image        = "sethvargo/http-echo"
        network_mode = "host"

        args = [
          "--peer=hab-sup.service.consul",
          "--listen-http=${NOMAD_ADDR_hab_http}",
          "--listen-gossip=${NOMAD_ADDR_hab_gossip}",
        ]
      }

      resources {
        cpu    = 20  # MHz
        memory = 128 # MB

        network {
          mbits = 5

          port "http"{}
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
}
