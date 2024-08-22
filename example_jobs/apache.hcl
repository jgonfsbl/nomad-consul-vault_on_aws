job "demo-webapp" {
  datacenters = ["dc1"]
  type = "service"

  group "demo" {
    count = 2 
    network {
      port "http" { 
        to = 80
      }
    }

    service {
      name = "demo-webapp"
      port = "http"
      check {
        type     = "http"
        path     = "/"
        interval = "2s"
        timeout  = "2s"
      }
    }

    task "apache" {

     env {
        PORT    = "${NOMAD_PORT_http}"
        NODE_IP = "${NOMAD_IP_http}"
      }
      
      driver = "docker"
      
      config {
        image = "httpd:latest"
        ports = ["http"]
      }

      resources {
        cpu    = 100
        memory = 100
      }
    
    }
  }
}
