# Node name
node_name = "ncv-srv-1"

# Datacenter name
datacenter = "dc1"

# Consult data folder
data_dir = "/opt/consul"

# Log level
log_level = "INFO"

# Server mode - Minimum 3 servers for quorum
server = true
bootstrap_expect = 3

# LAN network bindings
bind_addr = "10.0.129.243"
client_addr = "0.0.0.0"

addresses {
  dns = "0.0.0.0"
  grpc = "0.0.0.0"
  http = "0.0.0.0"
  https = "0.0.0.0"
}

# Consul domain for DNSMasq integration and query
domain = "consul"

# Interface Web UI
ui_config {
  enabled = true
}

# Encyption detail / Use 'consul keygen' for generation
encrypt = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

# WAN setup
retry_join = ["provider=aws tag_key=consul_node_type tag_value=server addr_type=private_v4 service=ec2 region=eu-south-2"]


# Gossip (optional)
retry_interval = "30s"

# Security (TLS)
tls {
  defaults {
    verify_incoming = true
    verify_outgoing = true
    ca_file   = "/etc/consul.d/certs/consul-agent-ca.pem"
    cert_file = "/etc/consul.d/certs/dc1-server-consul-1.pem"
    key_file  = "/etc/consul.d/certs/dc1-server-consul-1-key.pem"
  }
}

auto_encrypt {
  allow_tls = true
}

# Enable ACLs, set default policy and persist tokens
acl = {
  enabled = true
  default_policy = "deny"
  enable_token_persistence = true
  # This is a shared token for Consul and Nomad. See Consul UI for more details.
  tokens {
    agent = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  }
}

# Logging
enable_syslog = true
syslog_facility = "local0"
