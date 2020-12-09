#!/usr/bin/env bash
# Script to deploy an nginx ingress controller using Helm3 to either EKS/GKE or AKS.
#set -oe pipefail

# Version is currently not used. We default to installing the latest stable version in the helm repo.
#VERSION="0.34.1"

IP_OPTS=""

usage() {
    echo -e "\nUsage: $0 [-g|--gke <ip-address>] [-e|--eks] [-a|--aks] [-d|delete] [-h|--help]\n"
    echo -e "\t -g, --gke:      -   deploy to GKE. Optionally provide IP address (default: dynamically generate IP address)"
    echo -e "\t -e, --eks:      -   deploy to EKS"
    echo -e "\t -a, --aks:      -   deploy to AKS"
    echo -e "\t -d, --delete:   -   delete ingress controller"
    echo -e "\t -h, --help:     -   display options"

    exit 2
}

# Delete Helm chart
delete() {
    helm uninstall ingress-nginx --namespace nginx || true
    exit 1
}

# If an argument is provided, ensure that it is either delete or an IP address for GKE
if [[ $# > 0 ]]; then
    case $1 in
        -d|--delete)
            echo "Deleting Ingress Controller Helm chart."
            delete
        ;;
        -g|--gke)
            if [[ "$#" == 2 ]]; then
                # Check IP address format and don't continue if not valid.
                [[ ! "$2" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && echo -e "\nERROR: Can't detect a valid IP address" && usage

                # Set the loadBalancerIP annotation.
                echo "IP: $2"
                IP_OPTS="--set controller.service.loadBalancerIP=${2}"
            fi
            echo -e "Deploying Ingress Controller to GKE...\n"
            PROVIDER="GKE"
        ;;
        -e|--eks)
            echo -e "Deploying Ingress Controller to EKS...\n"
            PROVIDER="EKS"
        ;;
        -a|--aks)
            echo -e "Deploying Ingress Controller to AKS...\n"
            PROVIDER="AKS"
        ;;
        -h|--help)
            usage
        ;;
        *)
            usage
        ;;
    esac
fi

# Create namespace
ns=$(kubectl get namespace | grep nginx | awk '{ print $1 }' || true)

# Identify cluster size
clustsize=$(kubectl get nodes --label-columns forgerock.io/cluster --no-headers  | head -n 1 | awk '{print $6}')

if [ -z "${ns}" ]; then
    kubectl create namespace nginx
else
    printf "*** nginx namespace already exists ***\n"
fi

if [ -n "$clustsize" ]; then
    echo "Detected cluster of type: $clustsize"
fi 

if [[ -n "$clustsize" && ($clustsize == "cdm-medium" || $clustsize == "cdm-large") ]]; then 
    echo "Setting ingress pod count to 3"
    INGRESS_POD_COUNT=3
elif [[ -n "$clustsize" && ($clustsize == "cdm-small") ]]; then 
    echo "Setting ingress pod count to 2"
    INGRESS_POD_COUNT=2
else 
    echo "Setting ingress pod count to 1"
    INGRESS_POD_COUNT=1
fi

# Set script location
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
ADDONS_BASE="${ADDONS_BASE:-${DIR}/../cluster/addons}"
ADDONS_DIR="${ADDONS_BASE}/nginx-ingress-controller"

# Add Helm repo
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx --force-update

# Deploy ingress controller Helm chart
helm upgrade -i ingress-nginx --namespace nginx ingress-nginx/ingress-nginx \
    $IP_OPTS -f ${ADDONS_DIR}/${PROVIDER}.yaml --set controller.replicaCount=${INGRESS_POD_COUNT}