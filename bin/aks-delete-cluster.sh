#!/usr/bin/env bash
# Copyright (c) 2016-2017 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file
#
# Sample script to delete a kubernetes cluster and assoicatec resource group  on AKS
# You must have the az command installed and access to a Azure account

set -o errexit
set -o pipefail
set -o nounset

source "${BASH_SOURCE%/*}/../etc/aks-env.cfg"


echo "=> Read the following env variables from config file"
echo -e "\tCluster Name = ${AKS_CLUSTER_NAME}"
echo -e "\tResource Group = ${AKS_RESOURCE_GROUP_NAME}"

echo "=> Do you want to continue to delete the cluster with these settings?"
read -p "Continue (y/n)?" choice
case "${choice}" in 
   y|Y|yes|YES ) echo "yes";;
   n|N|no|NO ) echo "no"; exit 1;;
   * ) echo "Invalid input, Bye!"; exit 1;;
esac

echo ""
echo "=> Deleting Cluster \"${AKS_CLUSTER_NAME}\""
az aks delete --resource-group ${AKS_RESOURCE_GROUP_NAME} --name ${AKS_CLUSTER_NAME}

echo ""
echo "=> Deleting Resoure Group \"${AKS_RESOURCE_GROUP_NAME}\""
az group delete --resource-group ${AKS_RESOURCE_GROUP_NAME}




