name = "TPL_NAME"
region = "global"
datacenter = "dc1"

data_dir = "/opt/nomad/data"

log_level = "INFO"
enable_syslog = true

advertise {
  http = "TPL_IP"
   rpc = "TPL_IP"
  serf = "TPL_IP"
}

# This forces login to Nomad UI
acl {
  enabled = false
  token_ttl = "30s"
  policy_ttl = "60s"
}

# Nomad TLS Configuration
tls {
  http = true
  cert_file = "/etc/nomad.d/certs/nomad.crt"
  key_file = "/etc/nomad.d/certs/nomad.key"
  verify_https_client = false
}

consul {
  # The local Consul agent.
  address = "127.0.0.1:8500"
  token = "TPL_CONSUL_TOKEN_SERVER"
  server_auto_join = true
  server_service_name = "nomad-servers"
  auto_advertise = true
}

# telemetry {
#  publish_allocation_metrics = true
#  publish_node_metrics       = true
#  prometheus_metrics         = true
# }

###
### HERE WE DECIDE THE NOMAD BEHAVIOR TO TAKE
###

server {
    enabled = true
    raft_protocol = 3
    bootstrap_expect = 3
}

# EOF
