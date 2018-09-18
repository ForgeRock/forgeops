#!/usr/bin/env bash
# Copyright (c) 2016-2017 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file
#
# Sample script to create a Kubernetes cluster on Google Kubernetes Engine (GKE)
# You must have the gcloud command installed and access to a GCP project.
# See https://cloud.google.com/container-engine/docs/quickstart

set -o errexit
set -o pipefail
set -o nounset

source "${BASH_SOURCE%/*}/../etc/gke-env.cfg"


echo "=> Read the following env variables from config file"
echo -e "\tProject Name = ${GKE_PROJECT_NAME}"
echo -e "\tPrimary Zone = ${GKE_PRIMARY_ZONE}"
echo -e "\tAdditional Zones = ${GKE_NODE_LOCATIONS}"
echo -e "\tCluster Name = ${GKE_CLUSTER_NAME}"
echo -e "\tCluster Namespace = ${GKE_CLUSTER_NS}"
echo -e "\tCluster Monitoring Namespace = ${GKE_MONITORING_NS}"
echo -e "\tCluster Version = ${GKE_CLUSTER_VERSION}"
echo -e "\tCluster Size =  ${GKE_CLUSTER_SIZE}"
echo -e "\tVM Type = ${GKE_MACHINE_TYPE}"
echo -e "\tNetwork = ${GKE_NETWORK_NAME}"
echo -e "\tIngress Controller IP = ${GKE_INGRESS_IP}"
echo -e "\tExtra Arguments = ${GKE_EXTRA_ARGS}"
echo ""
echo "=> Do you want to continue creating the cluster with these settings?"
read -p "Continue (y/n)?" choice
case "${choice}" in 
   y|Y|yes|YES ) echo "yes";;
   n|N|no|NO ) echo "no"; exit 1;;
   * ) echo "Invalid input, Bye!"; exit 1;;
esac


echo ""
echo "=> Creating cluster called \"${GKE_CLUSTER_NAME}\" with specs \"${GKE_MACHINE_TYPE}\""
echo ""

MAX_NODES=`expr ${GKE_CLUSTER_SIZE} + 2`
MIN_NODES=${GKE_CLUSTER_SIZE}

if [ ! -z "${GKE_EXTRA_ARGS}" ]; then 
      GKE_EXTRA_ARGS="${GKE_EXTRA_ARGS}"
fi

if [ ! -z "${GKE_NODE_LOCATIONS}" ]; then 
      GKE_EXTRA_ARGS="${GKE_EXTRA_ARGS} --node-locations=${GKE_NODE_LOCATIONS}"
fi


aws eks create-cluster --name devel \
  --role-arn arn:aws:iam::111122223333:role/eks-service-role-AWSServiceRoleForAmazonEKS-EXAMPLEBKZRQR \
  --resources-vpc-config subnetIds=subnet-a9189fe2,subnet-50432629,securityGroupIds=sg-f5c54184

