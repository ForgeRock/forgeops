#!/usr/bin/env bash
# Copyright (c) 2016-2017 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file
#
# Sample script to create a Kubernetes cluster on Elastic Kubernetes Service (EKS)
# You must have the aws command installed and access EKS cluster.
# See https://docs.aws.amazon.com/cli/latest/userguide/awscli-install-bundle.html


set -o errexit
set -o pipefail
set -o nounset

VPC_STACK_NAME="forgeops-eks-vpc"

aws cloudformation deploy \
          --stack-name $VPC_STACK_NAME \
          --template-file ../etc/amazon-eks-vpc.yaml \
          --capabilities CAPABILITY_IAM


aws cloudformation describe-stacks --stack-name $VPC_STACK_NAME --output table --query 'Stacks[0].Outputs'

echo "Please record the above values for creating your EKS cluster."
echo "SecurityGroups: This security group allows the EKS cluster to communicate with your worker nodes. Value should be set to EC2_SECURITY_GROUP in your eks-env.cfg file."
echo "VpcId: This is used for creating the subnets in your EC2 account. Value should be set to EKS_VPC_ID in your eks-env.cfg file."
echo "SubnetIds: This is used to create subnets in your EC2 account where the worker nodes will be launched into. Value should be set to EKS_SUBNETS in your eks-env.cfg file."
