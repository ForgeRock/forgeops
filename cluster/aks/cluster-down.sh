#!/usr/bin/env bash

NAME=${NAME:-small}

RES_GROUP_NAME=${RES_GROUP_NAME:-"${NAME}-res-group"}

# Delete the cluster
echo "Deleting AKS cluster ${NAME}..."
az aks delete --yes --resource-group $RES_GROUP_NAME --name $NAME

# Delete the resource group
echo "Deleting resource group ${RES_GROUP_NAME}..."
az group delete --resource-group $RES_GROUP_NAME