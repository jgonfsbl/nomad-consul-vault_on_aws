# Nomad, Consul & Vault on AWS
Configuration files and documented procedure for the deployment of a Nomad, Consul and Vault datacenter in AWS. 

> [!IMPORTANT]  
> Work in Progress - Last update on Aug 23rd, 2024

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

After the EC2 Launch the user-data script will complete the job for consul agents, nomad workers, nomad servers and consul server other than the first. The first consul server suffer a chicken-egg problem and the best approach is to initialize it manually. Simnilarly, Vault servers are best initialized manually. 

###### EOF
