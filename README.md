# Nomad, Consul & Vault on AWS
Configuration files and documented procedure for the deployment of a Nomad, Consul and Vault datacenter in AWS. 

> [!IMPORTANT]  
> Work in Progress - Last update on Sep 1st, 2024

### Brief description of the process
To build a Nomad datacenter in AWS we want to leverage the benefits of Consul, as service registry and service discovery for our load balancers and for intention configuration (let's call it basic microsegmentation between workloads) and the benefits of Vault for secrets management and key management. 

Nomad, Consul and Vault are distribuited as a single binary file that needs to be downloaded from Hashicorp servers. To simplify this operation, Hashicorp have apt repositories (for debian, ubuntu) and yum repositories (for redhat, fedora, amazon linux) available. In the scenario described here the operating systems will be Ubuntu 24.04 LTS in ARM (Graviton) processors and the instance typs will be of series T4g, general purpose ARM. 

In essence the solution creates a datacenter out of AWS IaaS resources (VPC, EC2, CloudFront, ALB, ACM), PaaS resources (EFS) and some additional managed services (IAM, Config, Control Tower, IAM Identity Center, CloudTrail, Organizations) that compose the AWS Landing Zone reference architecture. 


### Implementation guide

<details>
<summary>1. VPC</summary>

### VPC configuration
When a Landing Zone with Control Tower is implemented a default VPC has been already populated. Nonetheless, if we want to automate in full the creation and destruction of all resoruces related to Nomad, Consul and Vault it's prefereable to create a fresh new VPC. 

To create a new VPC using the AWS Management Console (or IaC), this new VPC that should satisfy the setup described in folder [VPC](vpc/readme.md).
</details>



<details>
<summary>2. IAM</summary>
  
### IAM configuration
IAM service is a managed solution for everything related to security and identity. The configuration herein described affects to the necessary configuraion (role and policy) for the use of an EC2 Instance Profile, an IAM role that is assigned to an EC2 Instance so it can get access to other AWS services. 

To create the necessary IAM configuration (role, policy), the setup is described in the implementation detail document in folder [IAM](iam/readme.md).
</details>



<details>
<summary>3. EFS</summary>
  
### EFS configuration
EFS service is a managed solution for a shared NFS resource disk that can grow up to petabytes. In this scenario is going to be used as a mechanism to exchange files, templates, drivers and other resources between the server instances of Nomad/Consul/Vault and the worker/agent instances. 

To create a new EFS shared disk to be accesible vía NFS4 following, the setup is described in the implementation detail document in folder [EFS](efs/readme.md).
</details>



<details>
<summary>4. EC2</summary>
  
### EC2 setup
ECS service is a IaaS solution for virtualmachines that can scale based upon user confiuration rules. The instances can be of many types, from general purpose to those for an specific purpose, like those oriented to memory, compute or inference. In the scenario herein describe tme selection is general purpose using ARM architecture. The reationale is compute capacity by price point.  

To create a new EC2 instance, the setup is described in the implementation detail document in folder [EC2](ec2/readme.md).

Please note that the ideal scenario, with/without IaC, is to use a Launch Template to avoid misconfigurations and improve personalization.
</details>

After the EC2 Launch the user-data script will complete the job for consul agents, nomad workers, nomad servers and consul server other than the first. The first consul server suffer a chicken-egg problem and the best approach is to initialize it manually. Simnilarly, Vault servers are best unsealed manually. 



<details>
<summary>5. DNSMasq</summary>

### DNSMasq setup process
Here are the steps to follow:  
  
  1. Copy the file from EFS share to the right place, in `/etc/dnsmasq.conf`
  2. Disable Ubuntu´s SystemD Resolver
     `systemctl disable systemd-resolved.service`
     `systemctl stop systemd-resolved.service`
  4. Configure the `/etc/resolv.conf` appropiately with this content:
      ```
      nameserver 127.0.0.1
      search eu-south-2.compute.internal consul
      ``` 
  4. Enable and start services:  
       `systemctl enable dnsmasq`  
       `systemctl start dnsmasq`  
</details>



<details>
<summary>6. Consul</summary>

### Consul setup process
By the initialization of the first EC2 instance, that will operate as server, the first step is to configure the server. For this purpose there's a script called `nodeconfig.sh` that will populate a set of templates included herein with real values read from the IMDSv2 and a local .env file to personaliza all posible things in the server. When the configuration files are ready to run services, we'll start running command, taking note of values and fixing the configuration files minimally again. That's all. Here are the steps to follow:  
  
  1. Fix permission on folders:  
     `chmod consul:consul /etc/consul.d`  
  2. Initialize Consul's internal CA:  
       `consul tls ca create`
  3. Genearte certificates for all server instances using the internal CA (there are alternative methods using Vault described in the tech articles titled [Administer Consul access control tokens with Vault](https://developer.hashicorp.com/consul/tutorials/operate-consul/vault-consul-secrets), [Automatically Rotate Gossip Encryption Keys Secured in Vault](https://developer.hashicorp.com/consul/tutorials/operate-consul/vault-kv-consul-secure-gossip?productSlug=consul&tutorialSlug=vault-secure&tutorialSlug=vault-kv-consul-secure-gossip) and [Generate mTLS Certificates for Consul with Vault](https://developer.hashicorp.com/consul/tutorials/operate-consul/vault-pki-consul-secure-tls):  
     `consul tls cert create -server -dc dc1`  
       Repeat this command 3/5/7 times to generate 1 pair of certs per server instance. 
  4. In the `/etc/consul.d/consul.hcl` config file it's necessary to make some temporal adjustments to allow Consul to operate with only 1 node:
     - Change from `bootstrap_expect = 3` to `bootstrap_expect = 1`
     - Comment out block `retry_join`
     - Comment out `tls`
     - Comment out `auto_encrypt`
     - Change `acl` stanza:
       - Change from `default_policy = "deny"` to `default_policy = "allow"`
       - Comment out the `tokens` block
  5. Continue with configuration bits described in folder [Consul](consul/readme.md).
  6. Now that initial config has been completed in Consul, revert back the configuration options changed before and add more nodes to the Consul cluster. 
  7. Finally, enable and start services:  
       `systemctl enable consul`  
       `systemctl start consul`
</details>



<details>
<summary>7. Nomad</summary>

### Nomad setup process
Here are the steps to follow:  
  
  1. Fix permission on folders:  
     `chmod nomad:nomad /etc/nomad.d`  
  2. Copy certificates from EFS share to the right folder in `/etc/nomad.d`
  3. Enable and start services:  
       `systemctl enable nomad`  
       `systemctl start nomad`
  4. Finally, continue with configuration bits describecd in folder [Nomad](nomad/readme.md).
</details>





###### EOF
