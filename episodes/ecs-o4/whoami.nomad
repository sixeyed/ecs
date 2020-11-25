# apps are modelled in a hierarchy: job -> group -> task 

job "whoami" {

  datacenters = ["dc1"]

  group "web" {

    #count = 2
    
    network {
      port "http" {
        static = 8080
        to = 80
      }
    }

    task "api" {
      driver = "docker"
      config {
        image = "docker4dotnet/whoami"
        ports = ["http"]
      }
    }
  }
}