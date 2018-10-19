#!/usr/bin/env bash
# Copyright (c) 2016-2017 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file
#
# Sample script to create a Kubernetes cluster on Google Kubernetes Engine (EKS)
# You must have the gcloud command installed and access to a GCP project.
# See https://cloud.google.com/container-engine/docs/quickstart

set -o errexit
set -o pipefail
set -o nounset

source "${BASH_SOURCE%/*}/../etc/eks-env.cfg"

# TODO: echo vars dynamically by reading cfg file

echo "=> Read the following env variables from config file"
echo -e "\tStack Name = ${EKS_STACK_NAME}"
echo -e "\tCluster Name = ${EKS_CLUSTER_NAME}"
echo -e "\tCluster Version = ${EKS_CLUSTER_VERSION}"
echo -e "\tRole ARN = ${EKS_ROLE_ARN}"
echo -e "\tVPC ID = ${EKS_VPC_ID}"
echo -e "\tSubnets = ${EKS_SUBNETS}"
echo -e "\tSecuity Group = ${EC2_SECURITY_GROUP}"
echo ""
echo "=> Do you want to continue creating the cluster with these settings?"
read -p "Continue (y/n)?" choice
case "${choice}" in
   y|Y|yes|YES ) echo "yes";;
   n|N|no|NO ) echo "no"; exit 1;;
   * ) echo "Invalid input, Bye!"; exit 1;;
esac


echo ""
echo "=> Creating cluster called \"${EKS_CLUSTER_NAME}\""
echo ""

CLUSTER_ARN=$(aws eks create-cluster --name $EKS_CLUSTER_NAME \
              --role-arn $EKS_ROLE_ARN \
              --resources-vpc-config subnetIds=$EKS_SUBNETS,securityGroupIds=$EC2_SECURITY_GROUP \
              --query cluster.arn --output text)

echo "EKS Cluster is being created.  Usually it takes 10 minutes..."

while :
do
    CLUSTER_STATUS=$(aws eks describe-cluster \
                      --name $EKS_CLUSTER_NAME --query cluster.status --output text)

    if [ $CLUSTER_STATUS == "CREATING" ]; then
      echo "Waiting for EKS cluster to be ready..."
      sleep 60
    elif [ $CLUSTER_STATUS == "ACTIVE" ]; then
      echo "EKS cluster is ready"
      aws eks update-kubeconfig --name $EKS_CLUSTER_NAME --kubeconfig ~/.kube/config-eks
      export KUBECONFIG=$KUBECONFIG:~/.kube/config-eks
      kubectl config set-context ${CLUSTER_ARN}
      break
    else
      echo "Failed to create EKS cluster. Status: ${CLUSTER_STATUS}"
      exit 1
    fi

done
