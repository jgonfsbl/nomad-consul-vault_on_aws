job "redis" {

  region = "global"
  datacenters = ["dc1"]
  type = "service"
  priority = 50

  group "cache" {
    count = 1

    network {
      port "redis" {
        static = 6379
      }
    }

    service {
      name = "redis"
      port = "redis"
      tags = ["redis"]
      check {
        name = "redis port"
        type = "tcp"
        interval = "10s"
        timeout  = "2s"
      }
    }
    
    task "redis" {
      driver = "docker"

      env {
        NOMAD_LOG_LEVEL = "INFO"
      }

      logs {
        max_files     = 10
        max_file_size = 10
      }
      
      config {
        image = "redis:7.4.0-alpine3.20"
        ports = ["redis"]
        volumes = [
          "/opt/efs/redis/data:/data"
        ]
      }

     resources {
       cpu = 100 
       memory = 100
     }


    } // EndTask
  } // EndGroup
} // EndJob
