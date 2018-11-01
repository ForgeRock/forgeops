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

ROLE_NAME="eksServiceRole"

EKS_SERVICE_ROLE_ARN=$(aws iam create-role --role-name ${ROLE_NAME} --description "Allows EKS to manage clusters on your behalf." --assume-role-policy-document file://../etc/eks-service-role.json --query 'Role.Arn')

echo "EKS Role created with ARN ${EKS_SERVICE_ROLE_ARN}"

aws iam attach-role-policy --role-name ${ROLE_NAME} --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy
aws iam attach-role-policy --role-name ${ROLE_NAME} --policy-arn arn:aws:iam::aws:policy/AmazonEKSServicePolicy

echo "EKS/EC2 policies attached to the IAM role."
