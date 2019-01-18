#!/usr/bin/env bash
# Copyright (c) 2016-2018 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file
#
# Launches the second phase of the deployment from the ansible-config EC2 instance.



set -o errexit
set -o pipefail
set -o nounset

source "../etc/os-aws-env.cfg"

# Set the correct region on the AWS CLI
mkdir ~/.aws
echo [default] > ~/.aws/config
echo region = ${OS_AWS_REGION} >> ~/.aws/config


OS_AWS_AUTH=$(aws sts get-caller-identity --output text --query 'Arn')
OS_AWS_REGION=$(aws configure get region)

ask() {

	read -p "(y/n)" choice
	case "$choice" in
   		y|Y|yes|YES ) echo "yes";;
   		n|N|no|NO ) echo "no"; exit 1;;
   		* ) echo "Invalid input, Bye!"; exit 1;;
	esac
}



echo ""
echo ""
echo ""
echo "This script is to be run from the ansible-config host after the VPC and OpenShift cluster"
echo "have been created successfully."
echo ""
read -p "Press [Enter] to continue..."


echo ""
echo "=> Have you copied up your completed os-aws-env.cfg file to the local forgeops/etc directory"
echo "on the ansible-config instance?"
ask


echo ""
echo "=> You are authenticated and logged into AWS as \"${OS_AWS_AUTH}\""
echo "in the \"${OS_AWS_REGION}\" region. If this is not the account and/or region you wish to use,"
echo "exit this script and run \"aws configure\" to correct before continuing. Proceed?"
ask


# Get the ID of the ELB security group
OS_AWS_ELB_SG_ID=$(aws ec2 describe-security-groups --filters Name=tag:"aws:cloudformation:logical-id",Values=OpenShiftNodeSecurityGroup \
     --query 'SecurityGroups[0].GroupId'|sed s/\"//g)

# Get the public IP of the ansible-config instance
OS_AWS_ANSIBLE_INSTANCE_ID=$(curl http://169.254.169.254/latest/meta-data/instance-id)
OS_AWS_ANSIBLE_PUBLIC_IP=$(aws ec2 describe-instances --instance-id ${OS_AWS_ANSIBLE_INSTANCE_ID} \
    --query 'Reservations[0].Instances[0].NetworkInterfaces[0].Association.PublicIp'|sed s/\"//g)

# Add inbound rules to the security group allowing ports 80 and 443 from the ansible-config instance public IP
aws ec2 authorize-security-group-ingress --group-id ${OS_AWS_ELB_SG_ID} --protocol tcp --port 80 --cidr ${OS_AWS_ANSIBLE_PUBLIC_IP}/32
aws ec2 authorize-security-group-ingress --group-id ${OS_AWS_ELB_SG_ID} --protocol tcp --port 443 --cidr ${OS_AWS_ANSIBLE_PUBLIC_IP}/32

# Install and configure required software
./os-aws-required-software.sh

# Create storage classes
./os-aws-create-sc.sh

# Deploy cert manager
./os-aws-deploy-cert-manager.sh

# Deploy EFS
./os-aws-create-filesystem.sh

# Make sure we are on the OpenShift 'prod' project (and corresponding kubernetes namespace)
oc project prod

# Prompt user to exit current shell annd create a new one to ensure TILLER_NAMESPACE variable is set
# If it is not set helm commands will fail
echo "Exit the current shell after this script completes and enter \"sudo -s\" before continuing with"
echo "helm chart installations."
echo ""
read -p "Press [Enter] to continue..."





