job "todo-db" {

  datacenters = ["dc1"]
  type = "service"

  group "todo-db" {

    task "db" {
      driver = "docker"
      config {
        image = "diamol/postgres:11.5"        
        port_map {
          db = 5432
        }
      }
      resources {
        cpu    = 500 #MHz
        memory = 256 #MB
        network {
          port "db" {}
        }
      }
      service {
        name = "todo-db"
        address_mode = "driver"
        port = "db"
        check {
          name = "Postgres"
          interval = "10s"
          timeout  = "5s"
          type     = "tcp"
        }
      }
    }
  }
}