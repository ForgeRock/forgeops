#!/usr/bin/env bash
# Copyright (c) 2016-2017 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file
#
# Sample script to delegate permission for Service Principal to access Static IP resource Group
# You must have the az command installed and access to a Azure account

set -o errexit
set -o pipefail
set -o nounset

source "${BASH_SOURCE%/*}/../etc/aks-env.cfg"

## Get service principal client-id
SP_ID=$(az aks list --resource-group ${AKS_RESOURCE_GROUP_NAME} | grep -i clientId | awk '{ print $2 }' | cut -d \" -f2)

# Get Azure subscription ID
SUB=$(az account show |grep \"id\" | cut -d \" -f4)

az role assignment create\
   --assignee ${SP_ID} \
   --role "Network Contributor" \
   --scope /subscriptions/${SUB}/resourceGroups/${AKS_IP_RESOURCE_GROUP_NAME} || true
  
   

    
