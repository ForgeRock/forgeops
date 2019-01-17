# ForgeRock DevOps and Cloud Deployment Guide for OpenShift on AWS


## Introduction

This supplementary documentation has been prepared to guide you through the process of creating a
Redhat OpenShift Container Platform environment on AWS Cloud Services, and subsequently deploying 
the ForgeRock Devops examples into it.



## Prerequisites

1) An AWS account that can be used to deploy the OpenShift cluster.
2) An active Redhat OpenShift Enterprise 2 Core subscription with a minimum of 10 available
   entitlements (paid or evaluation). 



## High-Level Architecture

In this exercise we will deploy an OpenShift 3.11 cluster into a newly created and dedicated AWS VPC.
A description of this environment is as follows:

* The new VPC will be created with 3 availability zones, each with its own public and private subnets.
* Each availability zone will have its own NAT gateway for outbound internet access from the 
  private subnets.
* Each availability zone will contain one master node, one etcd node, and one worker node, all
  on the respective private subnet of the zone.
* The first availability zone will contain one instance that functions as both an ansible
  server that deploys the OpenShift cluster, and as a jump box, as it is the only instance that
  will have a public IP that you can connect to via SSH.
* One internal AWS elastic load balancer of type 'network' will be deployed to function as the
  OpenShift master node load balancer.
* One internet-facing AWS elastic load balancer of type 'classic' will be deployed to function as an
  OpenShift worker node load balancer will support ingress to applications.
* One internet-facing AWS elastic load balancer of type 'classic' will be deployed to function as an
  OpenShift worker node load balancer and will support access to the OpenShift Web UI.
* Public DNS records are registered in a public DNS hosted zone associated with your AWS account.
* Amazon Elastic File System (EFS) will be created to provide NFS storage for ForgeRock applications.



## AWS Quick Start Reference Deployment

The VPC and OpenShift cluster deployment are based on a customized version of AWS 'Quick Start' resources
that utilize AWS CloudFormation. Refer to the [Red Hat OpenShift Container Platform on the AWS Cloud](https://aws-quickstart.s3.amazonaws.com/quickstart-redhat-openshift/doc/red-hat-openshift-on-the-aws-cloud.pdf)
for more information. You can also review the original source repos and OpenShift Documentation:

[aws-quickstart/quickstart-redhat-openshift](https://github.com/aws-quickstart/quickstart-redhat-openshift)

[aws-quickstart/quickstart-aws-vpc](https://github.com/aws-quickstart/quickstart-aws-vpc)

[aws-quickstart/quickstart-linux-utilities](https://github.com/aws-quickstart/quickstart-linux-utilities)

[OpenShift 3.11 Documentation](https://docs.openshift.com/container-platform/3.11/welcome/index.html)



## AWS CLI

The scripts that will be executed as part of this deployment assume that you have an up to date version
of the AWS CLI locally installed and configured with your security credentials for your AWS account, and the correct region set. 

Note: These scripts have been tested in the us-east-1 region. 

If you don't have this installed and configured, refer to [Installing the AWS Command Line Interface](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html) documentation and follow the procedure for the appropriate platform before continuing.



## Creating an IAM Policy and Role

The CloudFormation scripts will require write access to a wide range of AWS services, including IAM,
in order to deploy successfully. 

Note: If you will be running these scripts using an IAM account with full privileges, you may skip
this section. 

If you are using an IAM account with limited privileges, you will first need to create an IAM role and
associated policy that has the necessary privileges. You will need help from an AWS admin to complete this.
A sample policy file is included in the repo in forgeops/etc/os-aws-policy. This will work without 
modifications or you can tailor it to suit your environment.

Create the policy:

1) From the AWS IAM web interface, create a new policy. 
2) Navigate to the JSON tab, and paste in the contents of the sample policy file.
3) Save the policy.

Create the role and associate the policy:

1) From the AWS IAM web interface, create a new role. 
2) Choose "CloudFormation" as the service that will be permitted to use the role.
3) Attach the policy created above to the role.
4) Save the role.



## Prepare an S3 Bucket

An S3 bucket is required for storing and referencing AWS OpenShift Quickstart artifacts.

1) Create a new bucket in S3
2) Copy the forgeops/etc/quickstart-redhat-openshift folder and all contents to the bucket



## Prepare the Parameters File

1) Copy forgeops/etc/os-aws-env.template to forgeops/etc/os-aws-env.cfg
2) Edit the cfg file. Carefully follow all instructions in it, enter parameter values, and
   save the cfg file.



## Launch the Deployment of the VPC and OpenShift Cluster

Navigate to the forgeops/bin directory and launch the installation:

```bash
  ./os-aws-up.sh
```

You will be asked whether or not you will be using an IAM role for the installation, and if so,
to confirm that you have entered that information into the os-aws-env.cfg file.

The complete installation of the VPC and cluster will take approximately 90 minutes. The script
will provide updates at 10 minute intervals until it completes. If the installation fails,
follow the instructions on screen. If the installation succeeds, an SSH session will automatically
be established to the ansible-config instance. 

If you wish, you can also connect to the OpenShift web interface. Note the value of the URL 
OpenShiftUI that is displayed on the screen after the installation completes, and navigate to this
URL in a browser.

login ID --> forgerock

pass --> (the value you entered in the os-aws-env.cfg file)



## Prepare the OpenShift Cluster

1) Establish an SSH session to the ansible-config instance and enter the following command:

```bash
  sudo -s
```

2) Clone this repo to the ansible-config instance.

3) Place a copy of your completed os-aws-env.cfg file in the forgeops/etc directory

4) The next step is to execute a wrapper script that installs software and configures the environment.
   This script performs the following actions:

   * Installs and configures Helm and other utilities
   * Creates an OpenShift project for installing the ForgeRock applications
   * Creates storage classes
   * Deploys the cert manager
   * Creates and configures an AWS Elastic File System

  (It is not necessary to install an nginx ingress controller in OpenShift as is done in other
  cloud environment as the equivalent functionality already exists).

  Navigate to forgeops/bin and execute the following:

```bash
  ./os-aws-up-ec2.sh
```


## Install the Helm Charts

Note: This procedure has been tested using the s-cluster template files. m-cluster or l-cluster 
template files will likely need larger instance types for the worker nodes specified in the
os-aws-env.cfg file prior to deploying the cluster.

1) Consult the instructions in the main ForgeOps guide for configuring required values in the Helm
   chart yaml files.
2) Launch the installation of the Helm Charts. Navigate to the forgeops/bin folder and execute the 
   following script:

```bash
  ./os-aws-deploy.sh
```


## Uninstall OpenShift and the AWS VPC

The following steps need to be taken to cleanly uninstall the OpenShift cluster and VPC

1) In the AWS console, navigate to the EFS service and delete the file system that was created. 
   In addition to matching the File System ID you should see 3 mount targets that are associated with 
   the VPC that was created for OpenShift.
2) We need to remove rules that were added to the security group associated with the container 
   access ELB after the cloudformation stack was deployed. Identify the ELB -- this information 
   is presented when you run the bin/os-aws-connect.sh script, or you can find it in EC2 with 
   the name format [Cluster Name]-Containe-[string]-[aws region].elb.amazonaws.com. In the description
   tab, click on the link for the Source Security Group. Edit the inbound rules and delete the
   2 rules that specify the elastic IP address of the ansible-config instance as the source, and save.
3) In the AWS console, navigate to the EC2 service. Identify the private DNS names in the properties 
   of all instances that were created in the deployment.
4) In the AWS console, navigate to the CloudFormation service. Identify the root OpenShift stack--it has
   the shortest name of the 3 and uses the format [stackname]-OpenShift. Delete this stack. It will
   automatically delete the 2 nested stacks along with it. This will take several minutes to complete.
   Verify that all 3 stacks deleted successfully.
5) Login to your Redhat Subscription Manager console and remove the registered systems that match the
   private DNS names identified in step 3. This will return the entitlements to the pool.
6) In the AWS console, navigate to the EC2 service (volumes). Delete any leftover EBS volumes created
   during the installation that are no longer needed.



## Modifications to Quick Start files


File: forgeops/etc/quickstart-redhat-openshift/scripts/templates/openshift.template

Modification: added 'arn:aws:iam::aws:policy/AmazonElasticFileSystemFullAccess' to the role used with
  the EC2 instance profile. This enables the automated deployment and configuration of EFS from the 
  scripts.




File: forgeops/etc/quickstart-redhat-openshift/scripts/ansibleconfigserver_bootstrap.sh

Modification: added 'ansible masters -a "htpasswd -b /etc/origin/master/htpasswd forgerock ${OCP_PASS}"'
  to create the forgerock user account in OpenShift.



