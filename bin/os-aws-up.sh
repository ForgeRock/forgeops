#!/usr/bin/env bash
# Copyright (c) 2016-2018 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file
#
# Sample wrapper script to initialize OpenShift on AWS. 



set -o errexit
set -o pipefail
set -o nounset

source "../etc/os-aws-env.cfg"

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

  read -p "(y/n/exit)" choice
  case "$choice" in
      y|Y|yes|YES ) echo "Deploying VPC and OpenShift stacks using your IAM account."; ./os-aws-create-vpc.sh;;
      n|N|no|NO ) echo "Deploying VPC and OpenShift stacks using IAM role."; ./os-aws-create-vpc-iam.sh;;
      exit ) echo "exiting..."; exit 0;; 
      * ) echo "Invalid input, Bye!"; exit 1;;
  esac
}

echo ""
echo ""
echo ""
echo "This script will create a new VPC and deploy an OpenShift Cluster within it using AWS"
echo "CloudFormation. A root stack and two nested stacks will be created as part of this process."
echo "A successful deployment will take approximately 90 minutes to complete, at which time all"
echo "3 stacks will have a status of \"CREATE_COMPLETE\"."
echo ""
read -p "Press [Enter] to continue..."


echo ""
echo "=> Have you copied the template file etc/os-aws-env.template to etc/os-aws-env.cfg and edited"
echo "to suit your environment?"
ask


echo ""
echo "=> You are authenticated and logged into AWS as \"${OS_AWS_AUTH}\""
echo "in the \"${OS_AWS_REGION}\" region. If this is not the account and/or region you wish to use,"
echo "exit this script and run \"aws configure\" to correct before continuing. Proceed?"
ask


# Deploy the vpc and cluster, first checking whether to run under an IAM account or role.
echo ""
echo "=> Is your AWS CLI configured to use an IAM account with full rights to all services?"
echo "If the answer is \"no\", be sure you've created an appropriate role and specified it"
echo "in os-aws-env.cfg, or exit this script to correct before continuing."
ask-iam





