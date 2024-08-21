# Node name
node_name = "ncv-wrk-1"

# Datacenter name
datacenter = "dc1"

# Consult data folder
data_dir = "/opt/consul"

# Log level
log_level = "INFO"

# This node acts as Consul Agent (not server)
server = false

# LAN network bindings
bind_addr = "10.0.182.148"
client_addr = "0.0.0.0"

# Optional: Enable the UI on this node (helpful for debugging)
ui = false  # Set to true for a local UI

# Enable local service registration and health checks
enable_local_script_checks = true

# Consul domain for DNSMasq integration and query
domain = "consul"

# Encyption detail / Use 'consul keygen' for generation
encrypt = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

# WAN setup
retry_join = ["provider=aws tag_key=consul_node_type tag_value=server addr_type=private_v4 service=ec2 region=eu-south-2"]

# Security (TLS)
tls {
  defaults {
    verify_incoming = true
    verify_outgoing = true
    ca_file   = "/etc/consul.d/certs/consul-agent-ca.pem"
    cert_file = "/etc/consul.d/certs/dc1-client-consul-1.pem"
    key_file  = "/etc/consul.d/certs/dc1-client-consul-1-key.pem"
  }
}

# Enable ACLs, set default policy and persist tokens
acl = {
  enabled = true
  # This is a shared token for Consul and Nomad. See Consul UI for more details.
  tokens {
    agent = "nnnnnnnn-nnnn-nnnn-nnnn-nnnnnnnnnnnn"
  }
}

# Logging
enable_syslog = true
syslog_facility = "local0"
