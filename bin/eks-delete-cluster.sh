#!/usr/bin/env bash
# Copyright (c) 2016-2017 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file

set -o errexit
set -o pipefail
set -o nounset

source "${BASH_SOURCE%/*}/../etc/eks-env.cfg"

echo "=> Read the following env variables from config file"
echo "Cluster Name = $EKS_CLUSTER_NAME"
echo "Stack Name = $EKS_STACK_NAME"
echo ""

echo "=> Do you want to delete the above cluster?"
read -p "Continue (y/n)?" choice
case "$choice" in 
   y|Y|yes|YES ) echo "yes";;
   n|N|no|NO ) echo "no"; exit;;
   * ) echo "Invalid input, Bye!"; exit;;
esac

echo "Removing nginx helm chart..."
helm del --purge nginx || true

echo "Removing ${EKS_MONITORING_NS} namespace..."
kubectl delete namespaces ${EKS_MONITORING_NS} || true
echo "Removing ${EKS_CLUSTER_NS} namespace..."
kubectl delete namespaces ${EKS_CLUSTER_NS} || true

echo "Removing storage classes..."
kubectl delete storageclass fast || true
kubectl delete storageclass standard || true

echo "Deleting the stack: ${EKS_STACK_NAME}"
aws cloudformation delete-stack --stack-name ${EKS_STACK_NAME}

echo "Deleting the cluster: ${EKS_CLUSTER_NAME}"
DELETE_CLUSTER=$(aws eks delete-cluster --name ${EKS_CLUSTER_NAME})