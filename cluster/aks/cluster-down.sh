#!/usr/bin/env bash

NAME=${NAME:-small}

RES_GROUP_NAME=${RES_GROUP_NAME:-"${NAME}-res-group"}

echo "The \"${NAME}\" cluster will be deleted. This action cannot be undone."
echo "Press any key to continue, or CTRL+C to quit"
read;

read -r -p "Do you want to delete all PVCs allocated by this cluster (recommended for dev clusters)? [Y/N] " response
case "$response" in
    [nN][oO]|[nN]) 
        echo
        echo "***The following PVCs will not be removed. You're responsible to remove them later***"
        kubectl get pvc --all-namespaces --no-headers
        ;;
    [yY][eE][sS]|[yY]) 
        echo
        echo "***Draining all nodes***"
        kubectl cordon -l forgerock.io/cluster
        kubectl delete pod --all-namespaces --all --grace-period=0
        echo
        echo "***Deleting all PVCs***"
        kubectl delete pvc --all-namespaces --all
        ;;
    *)
        echo "Invalid option. Please try again."
        exit 1
        ;;
esac

# Attempt to release any L4 service load balancers
echo 
echo "***Cleaning all services and load balancers if any***"
kubectl delete svc --all --all-namespaces

# Delete the cluster
echo "Deleting AKS cluster ${NAME}..."
az aks delete --resource-group $RES_GROUP_NAME --name $NAME --yes

# Delete the resource group
echo "Deleting resource group ${RES_GROUP_NAME}..."
az group delete --resource-group $RES_GROUP_NAME --yes