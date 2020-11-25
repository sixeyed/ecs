job "todo-web" {

  datacenters = ["dc1"]
  type = "service"

  group "todo-web" {

    count = 2

    task "web" {
      driver = "docker"
      config {
        image = "diamol/ch06-todo-list"
        dns_search_domains = ["service.dc1.consul"]
        dns_servers = ["SERVER-IP"]
        port_map {
          http = 80
        }
        volumes = [
          "local/config:/app/config"
        ]
      }
      env {
        # TODO - use Vault instead :)
        ConnectionStrings__ToDoDb = "Server=todo-db;Database=todo;User Id=postgres;Password=postgres;"
      }
      artifact {
        mode = "file"
        source      = "https://raw.githubusercontent.com/sixeyed/ecs/master/episodes/ecs-o4/todo-list-v2/configs/todo-web-config.json"
        destination = "local/config/config.json"
      }
      resources {
        cpu    = 250 #MHz
        memory = 256 #MB
        network {
          port "http" {
             static = 8010
          }
        }
      }
      service {
        name = "todo-web"
        port = "http"
        check {
          name = "To-do list"
          interval = "10s"
          timeout  = "5s"
          type     = "http"
          protocol = "http"
          path     = "/"
        }
      }
    }
  }
}