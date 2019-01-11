#!/usr/bin/env bash
# Copyright (c) 2016-2017 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file
#
# Sample script to create a kubernetes cluster on AKS
# You must have the az command installed and access to a Azure account

set -o errexit
set -o pipefail
set -o nounset

source "${BASH_SOURCE%/*}/../etc/aks-env.cfg"


echo "=> Read the following env variables from config file"
echo -e "\tCluster Name = ${AKS_CLUSTER_NAME}"
echo -e "\tCluster Location = ${AKS_LOCATION}"
echo -e "\tService Principal = ${AKS_SERVICE_PRINCIPAL}"
echo -e "\tService Principal Password = ${AKS_SERVICE_PRINCIPAL_SECRET}"
echo -e "\tAdmin Username = ${AKS_ADMIN_USERNAME}"
echo -e "\tResource Group = ${AKS_RESOURCE_GROUP_NAME}"
echo -e "\tKubernetes Version = ${AKS_KUBERNETES_VERSION}"
echo -e "\tNodes Per Zone = ${AKS_NODE_COUNT}"
echo -e "\tNode VM Size = ${AKS_NODE_VM_SIZE}"
echo -e "\tNode Disk Size = ${AKS_NODE_OSDISK_SIZE}"
echo -e "\tDefault Namespace = ${AKS_CLUSTER_NS}"
echo -e "\tMonitoring Namespace = ${AKS_MONITORING_NS}"
echo -e "\tExtra Arguments = ${AKS_EXTRA_ARGS}"
echo ""
echo "=> Do you want to continue creating the cluster with these settings?"
read -p "Continue (y/n)?" choice
case "${choice}" in 
   y|Y|yes|YES ) echo "yes";;
   n|N|no|NO ) echo "no"; exit 1;;
   * ) echo "Invalid input, Bye!"; exit 1;;
esac


# Who created this cluster.
CREATOR="${USER:-unknown}"
# Labels can not contain dots that may be present in the user.name
CREATOR=$(echo $CREATOR | sed 's/\./_/' | tr "[:upper:]" "[:lower:]")

# Check first to see if SPN exists
az ad sp show --id ${AKS_SERVICE_PRINCIPAL} > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Service Principal \"${AKS_SERVICE_PRINCIPAL}\" not found.  Please create first"
    exit 1
fi


echo ""
echo "=> Creating Resoure Group"
az group create \
   --name ${AKS_RESOURCE_GROUP_NAME} \
   --location ${AKS_LOCATION}

echo ""
echo "=> Creating cluster \"${AKS_CLUSTER_NAME}\" with node VM of \"${AKS_NODE_VM_SIZE}\""
echo "=> The resulting output of the cluster creation command is saved in your home directory"

if [ ! -z "${AKS_EXTRA_ARGS}" ]; then 
      AKS_EXTRA_ARGS="${AKS_EXTRA_ARGS}"
fi

# Create Cluster using CLI
az aks create \
    --resource-group ${AKS_RESOURCE_GROUP_NAME} \
    --name ${AKS_CLUSTER_NAME} \
    --admin-username ${AKS_ADMIN_USERNAME} \
    --location ${AKS_LOCATION} \
    --service-principal ${AKS_SERVICE_PRINCIPAL} \
    --client-secret ${AKS_SERVICE_PRINCIPAL_SECRET} \
    --kubernetes-version ${AKS_KUBERNETES_VERSION} \
    --node-vm-size ${AKS_NODE_VM_SIZE} \
    --node-osdisk-size ${AKS_NODE_OSDISK_SIZE} \
    --node-count ${AKS_NODE_COUNT} \
    --tag "createdby=${CREATOR}"  \
	--enable-addons monitoring \
    --generate-ssh-keys | tee -a "${HOME}/${AKS_CLUSTER_NAME}-create-output.json"

# Get cluster credentials to populate .kube/config 
az aks get-credentials \
	--resource-group ${AKS_RESOURCE_GROUP_NAME} \
    --name ${AKS_CLUSTER_NAME}
    
