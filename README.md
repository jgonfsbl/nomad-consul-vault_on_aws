# Nomad, Consul & Vault on AWS
Configuration files and documented procedure for the deployment of a Nomad, Consul and Vault datacenter in AWS. 

### Brief description of the process
To build a Nomad datacenter in AWS we want to leverage the benefits of Consul, as service registry and service discovery for our load balancers and for intention configuration (let's call it basic microsegmentation between workloads) and the benefits of Vault for secrets management and key management. 

Nomad, Consul and Vault are distribuited as a single binary file that needs to be downloaded from Hashicorp servers. To simplify this operation, Hashicorp have apt repositories (for debian, ubuntu) and yum repositories (for redhat, fedora, amazon linux) available. In the scenario described here the operating systems will be Ubuntu 24.04 LTS in ARM (Graviton) processors and the instance typs will be of series T4g, general purpose ARM. 

In essence the solution creates a datacenter out of AWS IaaS resources (VPC, EC2, CloudFront, ALB, ACM), PaaS resources (EFS) and some additional managed services (IAM, Config, Control Tower, IAM Identity Center, CloudTrail, Organizations) that compose the AWS Landing Zone reference architecture. 


### Implementation guide

<details>
<summary>1. VPC</summary>

### VPC configuration
Create a new VPC using the administrator console or IaC that satisfies the following setup:

#### Preview of the network setup
![image](https://github.com/user-attachments/assets/7ae960a0-2c71-4145-9913-5e48b7abb7e9)

#### Wizzard
![image](https://github.com/user-attachments/assets/d34fea36-4810-4b96-90f3-06b69a455427)
![image](https://github.com/user-attachments/assets/c3e42b46-0fc6-45cc-8ca1-c618a6600b84)

</details>



<details>
<summary>2. EFS</summary>
  
### EFS configuration
EFS service is a managed solution for a shared NFS resource disk that can grow up to petabytes. In this scenario is going to be used as a mechanism to exchange files, templates, drivers and other resources between the server instances of Nomad/Consul/Vault and the worker/agent instances. 

To create a new EFS shared disk to be accesible vía NFS4 following the setup is described in the implementation detail document, in folder [EFS](efs/readme.md).

</details>
