# Node name
node_name = "TPL_NAME"

# Datacenter name
datacenter = "dc1"

# Consult data folder
data_dir = "/opt/consul"

# Log level
log_level = "INFO"

# This node acts as Consul Agent (not server)
server = false

# LAN network bindings
bind_addr = "TPL_IP"
advertise_addr = "TPL_IP"
client_addr = "0.0.0.0"

# Optional: Enable the UI on this node (helpful for debugging)
ui_config {
  enabled = false # Set to true for a local UI
}

# Enable local service registration and health checks
enable_local_script_checks = true

# Consul domain for DNSMasq integration and query
domain = "consul"

# Encyption detail / Use 'consul keygen' for generation
encrypt = "TPL_KEYGEN" 

# WAN setup
retry_join = ["provider=aws tag_key=consul_node_type tag_value=server addr_type=private_v4 service=ec2 region=eu-south-2"]

# Security (TLS)
tls {
  defaults {
    verify_incoming = true
    verify_outgoing = true
    verify_server_hostname = true
    ca_file   = "/etc/consul.d/certs/consul-agent-ca.pem"
  }
  grpc {
    verify_incoming = false
  }
  https {
    verify_incoming = false
  }
}

auto_encrypt {
  tls = true
}

# Enable ACLs, set default policy and persist tokens
acl = {
  enabled = true
  tokens {
  # Policy: nomad-client / Token: Nomad Client Token
    agent = "TPL_CONSUL_TOKEN_CONSULNOMAD-AGENTWORKER"
  }
}

# Logging
enable_syslog = true
syslog_facility = "local0"

# EOF
