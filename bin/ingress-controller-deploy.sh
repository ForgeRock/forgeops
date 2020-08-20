#!/usr/bin/env bash
# Script to deploy an nginx ingress controller using Helm3 to either EKS/GKE or AKS.
#set -oe pipefail

# Version is currently not used. We default to installing the latest stable version in the helm repo.
#VERSION="0.34.1"

AKS_OPTS=""
IP_OPTS=""

usage() {
  printf "Usage: $0 -e|-g|-a [-i IP] [-r RESOURCE GROUP] [-d] \n\n"
  exit 2
}

delete() {
    helm uninstall ingress-nginx --namespace nginx || true
    exit 1
}


# Output help if no arguments or -h is included
if [[ $1 == "-h" ]];then
    printf "\nUsage: $0 -e|-g|-a [-i IP] [-r RESOURCE GROUP] [-d]\n"
    echo "-e                        : Deploy to EKS."
    echo "-g                        : Deploy to GKE."
    echo "-a                        : Deploy to AKS."
    echo "-i  <static IP address>   : Provide an existing static IP address(GKE/AKS only)"
    echo "-r  <resource group name> : Existing IP resource group name."
    echo "-d                        : delete nginx-ingress Helm chart."
    exit 1
fi

# Read arguments
while getopts :aegc:i:r:d option; do
    case "${option}" in
        e) PROVIDER="eks";;
        g) PROVIDER="gke";;
        a) PROVIDER="aks";;
        i) IP=${OPTARG};;
        r) RESOURCE_GROUP=${OPTARG};;
        d) delete;;
        h) usage ;;
        \?) echo "Error: Incorrect usage"
            usage
            exit 1;;
    esac
done

#******** VALIDATING ARGUMENTS ********
# Ensure provider flag has been provided.
[ -z "${PROVIDER}" ] && printf "\n** Please provide a provider flag (-g|-e|-a) **\n\n" && usage
# If -g or -a selected with -i then validate IP address format.
[[ "${PROVIDER}" =~ ^(gke|aks)$ ]] && [ "${IP}" ] && [[ ! "${IP}" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && printf '\n** IP address is not valid **\n\n' && usage
# If -g or -a selected with -i then set loadbalancer IP field.
[[ "${PROVIDER}" =~ ^(gke|aks)$ ]] && [ "${IP}" ] && IP_OPTS="--set controller.service.loadBalancerIP=${IP}"
# If -e is selected with -i, echo that IP address will be ignored
[[ "${PROVIDER}" =~ ^(eks)$ ]] && [ "${IP}" ] && printf "\n** IP address not required for EKS so ignoring **\n\n" && usage
# If -p is equal to 'aks', ensure -g is provided.
[[ "${PROVIDER}" =~ ^(aks)$ ]] && [ "${IP}" ] && [ -z "${RESOURCE_GROUP}" ] && printf "\n** AKS IP resource group required **\n\n" && usage
# If -p is equal to 'aks' and -g is provided, set IP resource group.
[[ "${PROVIDER}" =~ ^(aks)$ ]] && [ "${RESOURCE_GROUP}" ] && AKS_OPTS="--set controller.service.annotations.'service\.beta\.kubernetes\.io/azure-load-balancer-resource-group'=${RESOURCE_GROUP}"

# Create namespace
ns=$(kubectl get namespace | grep nginx | awk '{ print $1 }' || true)

if [ -z "${ns}" ]; then
  kubectl create namespace nginx
else
  printf "*** nginx namespace already exists ***\n"
fi

# Set script location
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
ADDONS_BASE="${ADDONS_BASE:-${DIR}/../cluster/addons}"
ADDONS_DIR="${ADDONS_BASE}/nginx-ingress-controller"

# Add Helm repo
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

# Deploy ingress controller Helm chart
helm upgrade -i ingress-nginx --namespace nginx ingress-nginx/ingress-nginx \
  $IP_OPTS $AKS_OPTS -f ${ADDONS_DIR}/${PROVIDER}.yaml

# This other repo requires changes to the values in cluster/addons/nginx-ingress-controller
# We're using `stable`, but need to explore if we should move to this other one. See CLOUD-2426
# # Add Helm repo
# helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx/ > /dev/null

# # Deploy ingress controller Helm chart
# helm upgrade -i nginx-ingress --namespace nginx ingress-nginx/ingress-nginx \
#   $IP_OPTS $AKS_OPTS -f ${ADDONS_DIR}/${PROVIDER}.yaml
