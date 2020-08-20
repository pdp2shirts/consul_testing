# F5 BIG-IP Terraform & Consul Webinar - Zero Touch App Delivery with F5, Terraform & Consul
- This repository will provision BIG-IP VE (Pay as you Go), Consul & NGINX servers in AWS

# Demo
You can check out a recording of this demo [here](https://youtu.be/rVTgTXpiopc?t=1489)

# Architecture
![Demo Arch](assets/f5_arch.png)

# How to use this repo

This repo comprises two main functions:

- Initial provisioning of the of the infrastructure in AWS\
    **Prerequisites:**
    - Amazon Web Services account
    - Computer with Git installed
    - Computer with Terraform installed. Please see this link for how to install [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli?in=terraform/aws-get-started)

- Github Actions workflows for ongoing operations\
    **Prerequisites:**
    - Amazon Web Services account
    - Computer with Git installed
    - Github accouunt

## Provision Infrastructure

- Option 1 - Setting up a complete new Application on your F5 BIG-IP through AS3 leveraging Consul integration: Follow the steps outlined below.
- Option 2 - Migrating an existing F5 BIG-IP deployment to leverage AS3 Consul integration: Follow the steps outlined in [`README.md`](brownfield-approach/README.md) within `brownfield-approach` subfolder.


The `terraform` directory has tf files for creating instances for Consul, F5, IAM policy, Nginx servers in an autoscale group.

- `main.tf` refers to what region is used on AWS.
- `ssh.tf` is used to create the key pairs.
- `vpc.tf` is used to create a new VPC and also to define the AWS security groups.
- `outputs.tf` is used to output and display F5 BIG-IP management IP and F5 BIG-IP dynamic Password


### Steps 
- Clone the repository & change working directory to terraform
```
git clone https://github.com/dgarrison63/consul_testing
cd consul_testing/terraform/
```

- Modify `terraform.tfvars.example` and define a **prefix** to add to each of your resources that are created in AWS to help uniquely identify them
- Modify `terraform.tfvars.example` and define the **region** to specify the AWS region where your resources will be created. Examples of AWS regions are "us-east-1", "us-west-1", etc.
- Rename `terraform.tfvars.example` to `terraform.tfvars`

From the root of the repo, run this command to create the infrastructure in AWS using Terraform
```
./create-demo.sh
```

  - This will create BIG-IP, Consul, NGINX instances on AWS
  - This will also seed a `terraform.tfvars` file and a `bucket.tf` in the `as3` directory for use in the next step
  - It may take up to 5 minutes or after the run is complete for the environment to become ready. The URLs for the BIG-IP UI and the Consul server are defined in the Terraform output.  Please verify you can reach the BIG-IP and Consul server before proceeding.


### Configure BIG-IP using AS3


Next we need to download and load AS3 rpm into BIG-IP, for AS3 documentation and download please refer to https://github.com/F5Networks/f5-appsvcs-extension  note :- this currently uses AS3 3.19.0 rpm image

```
terraform init
terraform plan
terraform apply
```

- Do terraform plan & apply, this will deploy the AS3 declarative JSON for service discovery on BIG-IP. It will use as3.tf file. You can review the `terraform.tfvars` file that was generated in the previous step or rename and edit `terraform.tfvars.example` file in that directory to pass the necessary variables to terraform, or enter them manually via the CLI, copying the format of the values in the file.
- Now you have Virtual IP and Pool information already configured on BIG-IP in partition defined in the consul.json file.

## How to test?
- You can access backend applications using http://VIP_IP:8080 where VIP_IP is the Elastic IP which maps to BIG-IP Private VIP_IP.
- The NGINX servers are already in Auto scale group with consul agents running and sending all information to Consul server.
- Use case is when you destroy or bring down  one of the NGINX server, BIG-IP AS3 will poll the consul server and update the pool members automatically
- So as the NGINX servers are going up and down the BIG-IP Pool members are updated automatically without manual intervention.  
- Use http://consul_public_IP:8500 to access the consul server and check the status of consul nodes count

## Github Actions Workflows
After the initial provisioning of the infrastructure in AWS, ongoing, daily operations are implemented in Github Actions workflows. Github Actions is a CI/CD tool integrated in to Github. These workflows run in Github and allow you to register and deregister new services in Consul and AS3 declarations in BIG-IP.

For more information about Github Actions workflows, please see [Github Actions](https://docs.github.com/en/actions/getting-started-with-github-actions/about-github-actions)

While the steps to provision the infrastructure are run locally on your desktop via Terraform, the Github Actions workflows are actually running in Github. What this means is that, in addition to cloning this repo to your local desktop, you will also need to have a Github account and clone this repo to an empty repo in Github.

Personal Github accounts are free and support Github Actions workflows. If you don't already have one, please see this link: [Signing up for Github](https://docs.github.com/en/github/getting-started-with-github/signing-up-for-github)

From your Github account, create an empty repository that will be populated from the Git repo on your local computer. For more information on how to create a new repo in Github, please see [Create a repo](https://docs.github.com/en/github/getting-started-with-github/create-a-repo).

Before you can populate your new, empty remote Github repo from your local Git repo, you will first need to disconnect your local Git repo from the original repo that you cloned from:
```
git remote rm origin
```

Push your local Git repo to your emtpy Github repo. Complete the following steps, replacing **myAccount** and **myRepo** with the appropriate values:
```
Change directory to the root of your local Git repo
git remote add origin https://github.com/**myAccount**/**myRepo**
git add s3/s3_bucket_params.json
git commit -m "added s3 bucket parameter file"
git push -u origin master
```

### Workflows
Workflows are automatically triggered when Consul or AS3 declarations are pushed to your Github repo.

Prerequisites:
  - Need to create two Github Secrets:
    + AWS_ACCESS_KEY_ID = `<AWS Access Key>`
    + AWS_SECRET_ACCESS_KEY = `<AWS Secret Access Key>`
|
For information on how to create Github secrets, please see [Github Secrets](https://docs.github.com/en/actions/configuring-and-managing-workflows/creating-and-storing-encrypted-secrets)  

There are four workflows defined:

**Register New Consul Service**
  -  Workflow uses the Consul command line interface (CLI) to register new services in Consul

**Deregister Existing Consul Service**
  -  Workflow uses the Consul command line interface (CLI) to de-register services in Consul

**Register New AS3 Declaration**
  - Workflow uses the F5 command line interface (CLI) to register new AS3 declarations on BIG-IP

**Deregister Existing AS3 Declaration**
  - Workflow uses the F5 command line interface (CLI) to de-register AS3 declarations from BIG-IP

## Test Github Actions workflows
Github Action workflows are triggered by Github events. In the following examples, the workflows are triggered when updates are pushed from your local Git repo to your Github repo. You can use the provided examples to test registering and deregistering Consul services and AS3 declarations or use your own.
|  
Use Cases:

**Register a new service in Consul**
```
Change directory to the root of your local Git repo
cp declarations/consul/examples/example-service.json declarations/consul/register
cd declarations/consul/register
git add example-service.json
git commit -m "Added new Consul service"
git push
```
Once completed, the new, example service should be registered and visible in the Consul dashboard. Additionally, you can view the workflow steps in the **Actions** section of your Github repo.

**De-register a service in Consul**
```
Change directory to the root of your local Git repo
cp declarations/consul/examples/example-service.json declarations/consul/deregister
cd declarations/consul/deregister
git add example-service.json
git commit -m "Deleted Consul service"
git push
```
Once completed, the example service should be de-registered and no longer visible in the Consul dashboard. Additionally, you can view the workflow steps in the **Actions** section of your Github repo.

**Register a new AS3 declaration on BIG-IP**
```
Change directory to the root of your local Git repo
cp declarations/as3/examples/example-as3.json declarations/as3/register
cd declarations/as3/register
git add example-as3.json
git commit -m "Added new AS3 declaration"
git push
```
Once completed, the new, example AS3 declaration should be registered in the BIG-IP. The example AS3 declaration creates a tenant (BIG-IP partion) named **Example**.

To view the BIG-IP configuration that was created from the example AS3 declaration, use the partition drop down and select the partition named **Example**.

Check out the virtual server, pool and pool members that were created with the pool members being populated automatically by the AS3 Consul service discovery process.
 
Additionally, you can view the workflow steps in the **Actions** section of your Github repo.

**De-register an existing AS3 declaration**  
```
Change directory to the root of your local Git repo
cp declarations/as3/examples/empty-example-as3.json declarations/as3/deregister
cd declarations/as3/deregister
git add empty-example-as3.json
git commit -m "Deleted AS3 declaration"
git push
```
Once completed, partition named **Example** and the associated BIG-IP configuration objects are deleted.
  
Additionally, you can view the workflow steps in the **Actions** section of your Github repo.  



## Repo Assets
### Folder as3
Folder as3 has three files, `main.tf`, `nginx.json` and `variables.tf`. `main.tf` is used to provision `nginx.json` template to BIG-IP once its ready.
This module attempts to download the rpom automatically, but you can also download the AS3 rpm module from https://github.com/F5Networks/f5-appsvcs-extension before doing terraform apply.

### Folder scripts
`consul.sh` is used to install consul
`f5.tpl` is used to change the admin password.
`nginx.sh` is used to install consul agent on nginx servers

### Product Versions
- BIG-IP image used is 15.1.04 version
- AS3 rpm used is [3.19.1 version](https://github.com/F5Networks/f5-appsvcs-extension/releases/download/v3.19.1/f5-appsvcs-3.19.1-1.noarch.rpm)
- HashiCorp & F5 webinar based on https://clouddocs.f5.com/cloud/public/v1/aws/AWS_singleNIC.html

### Worflow folders
