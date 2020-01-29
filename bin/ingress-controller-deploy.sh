#!/usr/bin/env bash
# Example of deploying an nginx ingress controller using Helm.
set -oe pipefail

# Helm chart values
VERSION="0.27.0"
AKS_OPTS=""
IP_OPTS=""

usage() {
  printf "Usage: $0 -e|-g|-a [-i IP] [-r RESOURCE GROUP] [-d] \n\n"
  exit 2
}

delete() {
    helm uninstall nginx-ingress --namespace nginx || true
    kubectl delete ns nginx
    exit 1
}


# Output help if no arguments or -h is included
if [[ $1 == "-h" ]];then
    printf "\nUsage: $0 -e|-g|-a [-i IP] [-r RESOURCE GROUP] [-d]\n"
    echo "-e  EKS."
    echo "-g  GKE."
    echo "-a  AKS."
    echo "-i  static IP address."
    echo "-r  IP resource group."
    echo "-d  delete nginx-ingress Helm chart."
    exit 1
fi

# Read arguments
while getopts :aegi:r:d option; do
    case "${option}" in
        e) PROVIDER="eks";;
        g) PROVIDER="gke";;
        a) PROVIDER="aks";;
        i) IP=${OPTARG};;
        r) RESOURCE_GROUP=${OPTARG};;
        d) delete;;
        h) usage ;;
        \?) echo "Error: Incorrect usage"
            echo usage
            exit 1;;
    esac
done

#******** VALIDATING ARGUMENTS ********
# Ensure -p has been provided.
[ -z "${PROVIDER}" ] && printf "\n** -p flag required **\n\n" && usage
# If -p is equal to 'gke or aks' then validate IP address format.
[[ "${PROVIDER}" =~ ^(gke|aks)$ ]] && [ "${IP}" ] && [[ ! "${IP}" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && printf '\n** IP address is not valid **\n\n' && usage
# If -p is equal to 'gke or aks' then validate IP address format.
[[ "${PROVIDER}" =~ ^(gke|aks)$ ]] && [ "${IP}" ] && IP_OPTS="--set controller.service.loadBalancerIP=${IP}"
# If -p is equal to 'gke', ensure -i is provided.
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

# Add Helm repo
helm repo add stable https://kubernetes-charts.storage.googleapis.com/ > /dev/null

# Deploy ingress controller Helm chart
helm upgrade -i nginx-ingress --namespace nginx stable/nginx-ingress \
  --set controller.image.tag=$VERSION \
  $IP_OPTS $AKS_OPTS -f ${DIR}/../cluster/addons/nginx-ingress-controller/${PROVIDER}.yaml
  