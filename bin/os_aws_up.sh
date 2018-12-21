#!/usr/bin/env bash
# Copyright (c) 2016-2018 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file
#
# Sample wrapper script to initialize OpenShift on AWS. 



set -o errexit
set -o pipefail
set -o nounset

source "../etc/os_aws_env.cfg"

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


ask-iam() {

  read -p "(y/n)" choice
  case "$choice" in
      y|Y|yes|YES ) echo "Deploying VPC and OpenShift stacks using your IAM account"; ./os_aws_create_vpc.sh;;
      n|N|no|NO ) echo "Deploying VPC and OpenShift stacks using IAM role"; ./os_aws_create_vpc_iam.sh;;
      * ) echo "Invalid input, Bye!"; exit 1;;
  esac
}


echo ""
echo "=> Have you copied the template file etc/os_aws_env.template to etc/os_aws_env.cfg and edited to suit your enviroment?"
ask


echo ""
echo "You are authenticated and logged into AWS as \"${OS_AWS_AUTH}\" in the \"${OS_AWS_REGION}\" region. If this is not the account and/or region you wish to use, exit this script and run \"aws configure\" to correct before continuing. Proceed?"
ask


# Deploy the vpc and cluster, first checking whether to run under an IAM account or role.
echo ""
echo "=> Is your AWS CLI configured to use an IAM account with full rights to all services? (If the answer is no, be sure you've created an appropriate role and specified it in os_aws_env.cfg, or exit this script to correct)"
ask-iam

# Informational
aws cloudformation describe-stacks --stack-name $OS_AWS_STACK_NAME --output table --query 'Stacks[0].Outputs'
export OS_AWS_ANSIBLE_HOST=$(aws ec2 describe-instances --filters 'Name=tag:Name,Values=ansible-configserver' --query 'Reservations[0].Instances[0].PublicDnsName'|sed s/\"//g)
echo ""
echo "Your ansible host public DNS registration is ---> ${OS_AWS_ANSIBLE_HOST}"
echo ""

# Establish an interactive SSH session to the ansible jumpbox in the VPC
echo "Adding the private key to the local ssh agent"
echo ""
ssh-add ${OS_AWS_PRIVATE_KEY_PATH}
echo ""
echo ""
echo "Establishing an interactive SSH session to the ansible jumbox in the VPC. Once connected, enter \"sudo -s\" and you will now have access to the OpenShift \"oc\" commands and can view the ansible configuration in \"/etc/ansible/hosts\". Respond \"yes\" when asked if you are sure you want to connect." 
echo ""
echo ""
ssh -A ec2-user@${OS_AWS_ANSIBLE_HOST}


