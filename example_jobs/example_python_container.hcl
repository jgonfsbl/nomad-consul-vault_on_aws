#
# How this example Nomad job works
#

#
# 
# Vault Block:
# ------------
# Added a vault block under the task with a policies key to specify the Vault policies that grant the necessary permissions 
# to access the secrets.
#
# Template Block:
# ---------------
# The template block is used to pull secrets from Vault and inject them into environment variables. Here, I used DB_PASS 
# to store the database password securely, and AUTH_PASSWORD for the Docker authentication password.
#
# The destination = "secrets/backend.env" specifies the file where these secrets are stored, and env = true tells Nomad 
# to treat the template output as environment variables.
#
# Updated Environment Variables:
# ------------------------------
# The environment variables DB_PASS and AUTH_PASSWORD are fetched from Vault dynamically at runtime, eliminating the need 
# to hardcode sensitive information in the Nomad job file.
#
#

# Name of the job
job "backend" {
  datacenters = ["dc1"]

  # Logical group for this resource
  # The `count` directive states the amount of artefacts to launch at once
  group "backend-services" {
    count = 1 

    # Define how networking should behave  
    network {
      port "gunicorn" { 
        static = 9000 
      }
    }

    # This stanza register the service being launched in Consul
    # In this case this is an example API built in Python. The `path` directive below
    # is used to check the API state of life. If the API requires authN & authZ it's 
    # advisable to have an enpoint in clear for Consul and the ingress/load balancer
    # to check for availability at any time. 
    service {
      name = "backend"
      port = "gunicorn"
      check {
        type     = "http"
        path     = "/status"
        interval = "2s"
        timeout  = "2s"
      }
    }

    # This is the where we define explicitly what we are launching
    task "backend-api" {    
      vault {
        policies = ["backend-policy"]
      }

      template {
        data = <<EOH
{{- with secret "secret/data/backend" -}}
export DB_PASS={{ .Data.data.db_password }}
export AUTH_PASSWORD={{ .Data.data.password }}
{{- end -}}
EOH
        destination = "secrets/backend.env"
        env         = true
      }

      # Environment variables to pass to the resource being launched
      env {
        DB_HOST        = "name.hash.region.rds.amazonaws.com"
        DB_USER        = "postgres"
        DB_PORT        = "5432"
        DB_NAME        = "api"
        DB_ENGINE      = "pg"
        FLASK_APP      = "app.py"
        FLASK_ENV      = "production"
        FLASK_DEBUG    = "False"
        FLASK_HOST     = "0.0.0.0"
        FLASK_PORT     = "9000"
        FLASK_LOG_LEVEL = "DEBUG"
        GUNIPORT       = "9000"
        VAULT_TOKEN    = "vault-token"
      }
      
      driver = "docker"
      config {
        image = "DH_username/backend:1.0.0-alpine"
        
        auth = {
          username = "DH_username"
          password = "{{with secret \"secret/data/backend\"}}{{.Data.data.password}}{{end}}"
        }

        ports = ["gunicorn"]
      }

      # This is the amount of resources Nomad will reserve for this job
      resources {
        cpu    = 100
        memory = 100
      }
    }
  }
}
