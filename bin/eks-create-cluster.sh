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


echo "=> Read the following env variables from config file"
echo -e "\tProject Name = ${EKS_PROJECT_NAME}"
echo -e "\tPrimary Zone = ${EKS_PRIMARY_ZONE}"
echo -e "\tAdditional Zones = ${EKS_NODE_LOCATIONS}"
echo -e "\tCluster Name = ${EKS_CLUSTER_NAME}"
echo -e "\tCluster Namespace = ${EKS_CLUSTER_NS}"
echo -e "\tCluster Monitoring Namespace = ${EKS_MONITORING_NS}"
echo -e "\tCluster Version = ${EKS_CLUSTER_VERSION}"
echo -e "\tCluster Size =  ${EKS_CLUSTER_SIZE}"
echo -e "\tVM Type = ${EKS_MACHINE_TYPE}"
echo -e "\tNetwork = ${EKS_NETWORK_NAME}"
echo -e "\tIngress Controller IP = ${EKS_INGRESS_IP}"
echo -e "\tExtra Arguments = ${EKS_EXTRA_ARGS}"
echo ""
echo "=> Do you want to continue creating the cluster with these settings?"
read -p "Continue (y/n)?" choice
case "${choice}" in 
   y|Y|yes|YES ) echo "yes";;
   n|N|no|NO ) echo "no"; exit 1;;
   * ) echo "Invalid input, Bye!"; exit 1;;
esac


echo ""
echo "=> Creating cluster called \"${EKS_CLUSTER_NAME}\" with specs \"${EKS_MACHINE_TYPE}\""
echo ""

MAX_NODES=`expr ${EKS_CLUSTER_SIZE} + 2`
MIN_NODES=${EKS_CLUSTER_SIZE}

if [ ! -z "${EKS_EXTRA_ARGS}" ]; then 
      EKS_EXTRA_ARGS="${EKS_EXTRA_ARGS}"
fi

if [ ! -z "${EKS_NODE_LOCATIONS}" ]; then 
      EKS_EXTRA_ARGS="${EKS_EXTRA_ARGS} --node-locations=${EKS_NODE_LOCATIONS}"
fi


aws eks create-cluster --name devel \
  --role-arn arn:aws:iam::111122223333:role/eks-service-role-AWSServiceRoleForAmazonEKS-EXAMPLEBKZRQR \
  --resources-vpc-config subnetIds=subnet-0a2d698ebae2fbb46,subnet-0bb82d2007138df3b,subnet-09594f97e0214d918,securityGroupIds=sg-0a9c85a3ed04623ef

