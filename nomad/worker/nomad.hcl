name = "ncv-wrk-1"
region = "global"
datacenter = "dc1"

data_dir = "/opt/nomad/data"

log_level = "INFO"
enable_syslog = true

bind_addr = "10.0.182.148"

advertise {
  http = "10.0.182.148"
  rpc  = "10.0.182.148"
  serf = "10.0.182.148"
}

# Consul integration for service discovery and health checks
consul {
  address = "127.0.0.1:8500"
  # Policy: nomad-client / Token: Nomad Client Token
  token = "a8cd99ec-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

  # Register the Nomad client as a service in Consul
  server_service_name = "nomad-servers"
  client_service_name = "nomad-clients"
  auto_advertise = true
  client_auto_join = true
  allow_unauthenticated = true
}

# Client settings: Nomad worker configuration
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

# Disable server mode
server {
  enabled = false
}

# Optional: Vault integration for secret management
# vault {
#   enabled = true
#   address = "http://127.0.0.1:8200"
#   token = "vault-root-token"
# }

# Optional: Plugin directory for custom plugins
plugin_dir = "/opt/efs/nomad-plugins"

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
