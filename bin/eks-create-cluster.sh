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
echo -e "\tCluster Name = ${EKS_CLUSTER_NAME}"
#echo -e "\tCluster Namespace = ${EKS_CLUSTER_NS}"
echo -e "\tCluster Role = ${EKS_ROLE_ARN}"
echo -e "\tCluster Subnet IDs = ${EKS_SUBNET_IDS}"
echo -e "\tCluster Security Group IDs = ${EKS_SECURITY_GROUP_IDS}"
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
echo "=> Creating Kubernetes Cluster called \"${EKS_CLUSTER_NAME}\""
echo ""


#if [ ! -z "${EKS_EXTRA_ARGS}" ]; then 
#      EKS_EXTRA_ARGS="${EKS_EXTRA_ARGS}"
#fi

#if [ ! -z "${EKS_NODE_LOCATIONS}" ]; then 
#      EKS_EXTRA_ARGS="${EKS_EXTRA_ARGS} --node-locations=${EKS_NODE_LOCATIONS}"
#fi


aws eks create-cluster --name ${EKS_CLUSTER_NAME} \
  --role-arn ${EKS_ROLE_ARN} \
  --resources-vpc-config subnetIds=${EKS_SUBNET_IDS},securityGroupIds=${EKS_SECURITY_GROUP_IDS}

