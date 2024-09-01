#!/bin/bash

# Debug mode active; change to +x to disable.
set -x

#
# This script decides which implementation of Nomad, Consul and Vault is
# required based upon instance tags and which network segment the instance is
# launched.
#
# A right combination will return a new server or worker/agent, whereas any
# wrong combination will remain the machine uninstalled, empty.
#


# ENVIRONMENT VARIABLES ######################################################

#
# The format and contents of an example .env file follows:
#
# :: .env ::
#
#   SERVER_SUBNETS="subnet-xxxxxxx subnet-yyyyyyy subnet-zzzzzzz"
#   TPL_KEYGEN="kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk"
#   TPL_CONSUL_TOKEN_CONSULNOMAD_AGENTWORKER=a8cd99ec-nnnn-nnnn-nnnn-nnnnnnnnnnnn
#   TPL_CONSUL_TOKEN_CONSULNOMAD_SERVER=2773eee6-nnnn-nnnn-nnnn-nnnnnnnnnnnn
#
# Please note, first two lines make use of double quotes, whereas the two
# second lines don't on purpose.
#

# Load .env file if it exists
if [ -f /opt/efs/.env ]; then
  echo "Loading environment variables from .env file"
  export $(cat /opt/efs/.env | grep -v '#' | awk '/=/ {print $1}')
else
  echo ".env file not found, using default values"
fi


# VARIABLES ##################################################################

# EFS mount point (from launch template)
EFS_MOUNT_POINT="/opt/efs"

# Server subnets
SERVER_SUBNETS_DEFAULT=("subnet-1" "subnet-2" "subnet-3")
SERVER_SUBNETS=${SERVER_SUBNETS:-${SERVER_SUBNETS_DEFAULT[@]}}

# Fetch instance metadata using IMDSv2
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/instance-id)
REGION=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region)
SUBNET_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/ | head -n 1)/subnet-id)
PRIVATE_IP=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/local-ipv4)

# Get tags
INSTANCE_NAME=$(aws ec2 describe-tags --region "$REGION" --filters "Name=resource-id,Values=$INSTANCE_ID" "Name=key,Values=Name" --query "Tags[0].Value" --output text)
NOMAD_NODE_TYPE=$(aws ec2 describe-tags --region "$REGION" --filters "Name=resource-id,Values=$INSTANCE_ID" "Name=key,Values=nomad_node_type" --query "Tags[0].Value" --output text)
CONSUL_NODE_TYPE=$(aws ec2 describe-tags --region "$REGION" --filters "Name=resource-id,Values=$INSTANCE_ID" "Name=key,Values=consul_node_type" --query "Tags[0].Value" --output text)

# Chicken-Egg problem for servers: variables cannot be populated because
# they are not yet built.
#
# For agent/worker this can be done here by entering data matually.
TPL_NAME="$INSTANCE_NAME"
TPL_IP="$PRIVATE_IP"

TPL_KEYGEN_DEFAULT="HERE-consul-encrypt-key"                               # Generated using `consul keygen`
TPL_CONSUL_TOKEN_CONSULNOMAD_AGENTWORKER_DEFAULT="HERE-agentworker-token"  # Manually replace
TPL_CONSUL_TOKEN_CONSULNOMAD_SERVER_DEFAULT="HERE-server-token"            # Manually replace

# Use values from .env if they exist, otherwise use the defaults
TPL_KEYGEN=${TPL_KEYGEN:-$TPL_KEYGEN_DEFAULT}
TPL_CONSUL_TOKEN_CONSULNOMAD_AGENTWORKER=${TPL_CONSUL_TOKEN_CONSULNOMAD_AGENTWORKER:-$TPL_CONSUL_TOKEN_CONSULNOMAD_AGENTWORKER_DEFAULT}
TPL_CONSUL_TOKEN_CONSULNOMAD_SERVER=${TPL_CONSUL_TOKEN_CONSULNOMAD_SERVER:-$TPL_CONSUL_TOKEN_CONSULNOMAD_SERVER_DEFAULT}


# SCRIPT #####################################################################

# Determine if it's a server based on the subnet and tags
IS_SERVER="false"
for subnet in "${SERVER_SUBNETS[@]}"; do
  if [[ "$NOMAD_NODE_TYPE" == "server" && "$CONSUL_NODE_TYPE" == "server" ]]; then
    IS_SERVER="true"
    break
  fi
done


# Prepare DNSMasq
rm -f /etc/dnsmasq.conf
systemctl disable systemd-resolved.service
systemctl stop systemd-resolved.service
rm -f /etc/resolv.conf
echo "nameserver 127.0.0.1" >> /etc/resolv.conf
echo "search $REGION.compute.internal consul" >> /etc/resolv.conf
cp "$EFS_MOUNT_POINT/dnsmasq/dnsmasq.conf" "/etc/dnsmasq.conf"
systemctl enable dnsmasq
systemctl start dnsmasq


# Prepare the local directories for Nomad, Consul and Vault
rm -rf /etc/consul.d/*
rm -rf /etc/nomad.d/*
mkdir -p /etc/consul.d
mkdir -p /etc/consul.d/certs
mkdir -p /etc/nomad.d
mkdir -p /etc/nomad.d/certs


# Modify configuration files based on role and metadata
if [[ "$IS_SERVER" == "true" ]]; then

  # Copy SERVER configuration files from EFS
  cp "$EFS_MOUNT_POINT/consul/server/consul.hcl.tpl" "/etc/consul.d/consul.hcl"
  cp "$EFS_MOUNT_POINT/nomad/server/nomad.hcl.tpl" "/etc/nomad.d/nomad.hcl"

  # Replace placeholders in the template files
  sed -i "s/TPL_NAME/$TPL_NAME/g" "/etc/consul.d/consul.hcl"
  sed -i "s/TPL_IP/$TPL_IP/g" "/etc/consul.d/consul.hcl"
  sed -i "s|TPL_KEYGEN|$TPL_KEYGEN|g" "/etc/consul.d/consul.hcl"
  sed -i "s/TPL_CONSUL_TOKEN_CONSULNOMAD-SERVER/$TPL_CONSUL_TOKEN_CONSULNOMAD_SERVER/g" "/etc/consul.d/consul.hcl"

  # Duplicate the process for Nomad template
  sed -i "s/TPL_NAME/$TPL_NAME/g" "/etc/nomad.d/nomad.hcl"
  sed -i "s/TPL_IP/$TPL_IP/g" "/etc/nomad.d/nomad.hcl"
  sed -i "s/TPL_CONSUL_TOKEN_CONSULNOMAD-SERVER/$TPL_CONSUL_TOKEN_CONSULNOMAD_SERVER/g" "/etc/nomad.d/nomad.hcl"

else

  # Copy WORKER/AGENT configuration files from EFS
  cp "$EFS_MOUNT_POINT/consul/agent/consul.hcl.tpl" "/etc/consul.d/consul.hcl"
  cp "$EFS_MOUNT_POINT/nomad/worker/nomad.hcl.tpl" "/etc/nomad.d/nomad.hcl"

  # Replace placeholders in the template files
  sed -i "s/TPL_NAME/$TPL_NAME/g" "/etc/consul.d/consul.hcl"
  sed -i "s/TPL_IP/$TPL_IP/g" "/etc/consul.d/consul.hcl"
  sed -i "s|TPL_KEYGEN|$TPL_KEYGEN|g" "/etc/consul.d/consul.hcl"
  sed -i "s/TPL_CONSUL_TOKEN_CONSULNOMAD-AGENTWORKER/$TPL_CONSUL_TOKEN_CONSULNOMAD_AGENTWORKER/g" "/etc/consul.d/consul.hcl"

  # Duplicate the process for Nomad template
  sed -i "s/TPL_NAME/$TPL_NAME/g" "/etc/nomad.d/nomad.hcl"
  sed -i "s/TPL_IP/$TPL_IP/g" "/etc/nomad.d/nomad.hcl"
  sed -i "s/TPL_CONSUL_TOKEN_CONSULNOMAD-AGENTWORKER/$TPL_CONSUL_TOKEN_CONSULNOMAD_AGENTWORKER/g" "/etc/nomad.d/nomad.hcl"

fi


# Register services
systemctl enable consul
systemctl enable nomad

echo ""
echo "SERVICES READY TO LAUNCH FOR THE FIRST TIME; POTENTIAL INITIALIZATION BY HAND."
echo ""

# EOF
