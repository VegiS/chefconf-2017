job "hab" {
  datacenters = ["dc1"]
  type        = "service"

  priority = 80

  task "sup" {
    driver = "docker"

    config {
      image        = "habitat/hab-mgmt-sup"
      network_mode = "host"

      args = [
        "--permanent-peer",
      ]
    }

    service {
      port = "http"
      name = "hab-sup"
    }

    resources {
      cpu    = 1000 # MHz
      memory = 1024 # MB

      network {
        mbits = 20

        port "http" {
          static = 9631
        }

        port "gossip" {
          static = 9638
        }
      }
    }
  }
}
