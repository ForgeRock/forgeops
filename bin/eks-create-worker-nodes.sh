#!/usr/bin/env bash

# Copyright (c) 2016-2017 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file
#
# Sample script to create the worker nodes for a previously created EKS cluster using cloudformation


set -o errexit
set -o pipefail
set -o nounset

source "${BASH_SOURCE%/*}/../etc/eks-env.cfg"

cat ../etc/eks-cloudformation-parameters.template | \
sed "s|{{EKS_CLUSTER_NAME}}|$EKS_CLUSTER_NAME|" | \
sed "s|{{EKS_SECURITY_GROUPS}}|$EKS_SECURITY_GROUPS|" | \
sed "s|{{EKS_WORKER_NODES_GROUP}}|$EKS_WORKER_NODES_GROUP|" | \
sed "s|{{EKS_MIN_NODES}}|$EKS_MIN_NODES|" | \
sed "s|{{EKS_MAX_NODES}}|$EKS_MAX_NODES|" | \
sed "s|{{EKS_WORKER_NODE_INSTANCE_TYPE}}|$EKS_WORKER_NODE_INSTANCE_TYPE|" | \
sed "s|{{EKS_AMI_ID}}|$EKS_AMI_ID|" | \
sed "s|{{EKS_WORKER_NODE_SIZE_IN_GB}}|$EKS_WORKER_NODE_SIZE_IN_GB|" | \
sed "s|{{EKS_SSH_KEYPAIR_NAME}}|$EKS_SSH_KEYPAIR_NAME|" | \
sed "s|{{EKS_VPC_ID}}|$EKS_VPC_ID|" | \
sed "s|{{EKS_PANEL_SUBNET}}|$EKS_PANEL_SUBNET|" | \
sed "s|{{EKS_SUBNETS}}|$EKS_SUBNETS|" > ../etc/eks-cloudformation-parameters.cfg

CF_STACK_ID=`aws cloudformation create-stack --stack-name $EKS_STACK_NAME --template-body file://../etc/eks-cloudformation-template.yaml --parameters file://../etc/eks-cloudformation-parameters.cfg --capabilities CAPABILITY_IAM | jq -r '.StackId'`

echo "Creating Stack with ID: $CF_STACK_ID"


# TODO: Get status of CloudFormation
# TODO: Get RoleInstance ARN Id
