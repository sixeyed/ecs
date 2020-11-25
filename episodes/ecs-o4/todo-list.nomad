job "todo" {

  datacenters = ["dc1"]
  type = "service"

  group "todo" {

    task "db" {
      driver = "docker"
      config {
        image = "diamol/postgres:11.5"        
        port_map {
          db = 5432
        }
      }
      resources {
        network {
          port "db" {}
        }
      }
      service {
        name = "todo-db"
        address_mode = "driver"
        port = "db"
      }
    }

    task "web" {
      driver = "docker"
      config {
        image = "diamol/ch06-todo-list"
        dns_search_domains = ["service.dc1.consul"]
        dns_servers = ["SERVER-IP"]
        port_map {
          http = 80
        }
      }
      env {
        Database__Provider = "Postgres"
        ConnectionStrings__ToDoDb = "Server=todo-db;Database=todo;User Id=postgres;Password=postgres;"
      }
      resources {
        network {
          port "http" {
             static = 8010
          }
        }
      }
    }
  }
}