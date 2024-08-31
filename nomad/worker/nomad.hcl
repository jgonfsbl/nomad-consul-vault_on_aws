#############################################################################
#
# General
#

name = "ncv-wrk-1"
region = "global"
datacenter = "dc1"

data_dir = "/opt/nomad/data"

log_level = "INFO"
enable_syslog = true

bind_addr = "10.0.180.126"

advertise {
  http = "10.0.180.126"
  rpc  = "10.0.180.126"
  serf = "10.0.180.126"
}

#############################################################################
#
# Consul integration for service discovery and health checks
#

consul {
  address = "127.0.0.1:8500"
  token = "1e0edd55-4534-d582-7daa-541bc758b050"
  server_service_name = "nomad-servers"
  client_service_name = "nomad-clients"
  auto_advertise = true
  client_auto_join = true
  allow_unauthenticated = true
}

#############################################################################
#
# Disable server mode
#

server {
  enabled = false
}

#############################################################################
#
# Client settings: Nomad worker configuration
#

client {
  enabled = true

  # Group nodes by type (optional)
  node_class = "general-purpose"

  # Reserve resources on the node for system tasks
  # reserved {
  #  cpu    = 500    # CPU in MHz
  #  memory = 512    # Memory in MB
  # }
}

#############################################################################
#
# Optional: Vault integration for secret management
#
# vault {
#   enabled = true
#   address = "http://127.0.0.1:8200"
#   token = "vault-root-token"
# }

#############################################################################
#
# Optional: Plugin directory for custom plugins
#

plugin_dir = "/opt/efs/nomad-plugins"

plugin "docker" {
  config {
    volumes {
      enabled = true
    }
  }
}

plugin "raw_exec" {
  config {
    enabled = true
  }
}

plugin "qemu" {
  config {
    image_paths    = ["/opt/efs/nomad-qemu-images"]
    args_allowlist = ["-drive", "-usbdevice"]
  }
}

# EOF
