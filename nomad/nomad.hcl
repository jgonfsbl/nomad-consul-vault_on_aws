name = "ncv-srv-1"
region = "global"
datacenter = "dc1"

data_dir = "/opt/nomad/data"

log_level = "INFO"
enable_syslog = true

advertise {
  http = "10.0.129.243"
   rpc = "10.0.129.243"
  serf = "10.0.129.243"
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
  # The address to the Consul agent.
  address = "127.0.0.1:8500"
  token = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

  # The service name to register the server and client with Consusl.
  # ONLY ONE OPTION SHOULD BE SELECTED BELOW DEPENDING ON THE NOMAD ROLE
  server_service_name = "nomad-servers"
  # client_service_name = "nomad-clients"

  # Enables automatically registering the services.
  auto_advertise = true

  # Enabling the server and client to bootstrap using Consul.
  # ONLY ONE OPTION SHOULD BE SELECTED BELOW DEPENDING ON THE NOMAD ROLE
  server_auto_join = true
  # client_auto_join = true
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
