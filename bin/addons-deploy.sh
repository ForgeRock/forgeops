#!/usr/bin/env bash
# Script to deploy or remove Nginx Ingress Controller, cert-manager and Prometheus Operator.
# ./addons-deploy.sh -g                 deploy to GKE.
# ./addons-deploy.sh -g -i <ip address> deploy to GKE with static IP address of Ingress.
# ./addons-deploy.sh -e                 deploy to EKS
# ./addons-deploy.sh -a                 deploy to AKS
# ./addons-deploy.sh -a                 deploy to AKS
# Run ./addons-deploy.sh -a -i <ip address> -r <ip resource group name> deploy to AKS with static IP for Ingress and resource group name where IP is configured.
# Run ./addons-deploy.sh -d             delete all

set -oe pipefail

# Set script location
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
INGRESS_ARGS=""
CERTMGR_ARGS=""
PROM_NAMESPACE=""
PROM_VALUES=""
CERTMGR_VERSION="v0.13.0"
PROM_NS=monitoring

usage() {
    printf "Usage: $0 -e|-g|-a [-i IP] [-r RESOURCE GROUP] [-v PROMETHEUS VALUES] [-n PROMETHEUS NAMESPACE] [-l] [-d]\n\n"
    exit 2
}

delete() {

    set +e

    # Delete cert-manager if cert-manager namespace exists
    if [ $(kubectl get namespace | grep cert-manager | awk '{ print $1 }') ]; then
        kubectl delete --wait=true -f https://github.com/jetstack/cert-manager/releases/download/${CERTMGR_VERSION}/cert-manager.yaml
    fi

    # Delete Nginx Ingress Controller if nginx namespace exists
    if [ $(kubectl get namespace | grep nginx | awk '{ print $1 }') ]; then
        helm uninstall nginx-ingress --namespace nginx
        kubectl delete ns nginx
    fi

    # Delete Prometheus Operator if monitoring namespace exists
    if [ $(kubectl get namespace | grep monitoring | awk '{ print $1 }') ]; then
        # Delete Prometheus Operator Helm chart
        helm uninstall prometheus-operator --namespace=$PROM_NS

        # Delete forgerock-metrics Helm chart
        helm delete forgerock-metrics --namespace=$NAMESPACE

        # Delete CRDs
        kubectl delete --wait=true crd prometheuses.monitoring.coreos.com
        kubectl delete --wait=true crd servicemonitors.monitoring.coreos.com
        kubectl delete --wait=true crd servicemonitors.monitoring.coreos.com
        kubectl delete --wait=true crd podmonitors.monitoring.coreos.com
        kubectl delete --wait=true crd alertmanagers.monitoring.coreos.com

        # Delete monitoring namespace
        kubectl delete ns $PROM_NS
    fi

    exit 1
}

# Output help if no arguments or -h is included
if [[ $1 == "-h" ]]; then
    printf "\nUsage: $0 -e|-g|-a [-i IP] [-r RESOURCE GROUP] [-v PROMETHEUS VALUES] [-n PROMETHEUS NAMESPACE] [-l] [-d]\n"
    echo "-e                        : Deploy to EKS."
    echo "-g                        : Deploy to GKE."
    echo "-a                        : Deploy to AKS."
    echo "-i  <static IP address>   : Provide an existing static IP address(GKE/AKS only)"
    echo "-r  <resource group name> : Existing IP resource group name."
    echo "-v                        : Prometheus custom values."
    echo "-l                        : Switch to Let's Encrypt Issuer"
    echo "-d                        : delete nginx-ingress Helm chart."
    exit 1
fi

# Read arguments
while getopts :aegi:r:v:n:lhd option; do
    case "${option}" in
    e) PROVIDER="-e" ;;
    g) PROVIDER="-g" ;;
    a) PROVIDER="-a" ;;
    i) IP=${OPTARG} ;;
    r) RESOURCE_GROUP=${OPTARG} ;;
    v) PROMETHEUS_VALUES=${OPTARG} ;;
    n) PROMETHEUS_NAMESPACE=${OPTARG} ;;
    l) ISSUER="-l" ;;
    d) delete ;;
    h) usage ;;
    \?)
        echo "Error: Incorrect usage"
        echo usage
        exit 1
        ;;
    esac
done

#******** VALIDATING ARGUMENTS ********
# Ensure provider flag has been provided.
[ -z "${PROVIDER}" ] && printf "\n** Please provide a provider flag for Nginx Ingress Controller (-g|-e|-a) **\n\n" && usage
INGRESS_ARGS=$PROVIDER
[ "${IP}" ] && INGRESS_ARGS="${INGRESS_ARGS} -i ${IP}"
[ "${RESOURCE_GROUP}" ] && INGRESS_ARGS="${INGRESS_ARGS} -r ${RESOURCE_GROUP} "
[ "${PROMETHEUS_VALUES}" ] && PROM_VALUES="-v ${PROMETHEUS_VALUES} "
[ "${PROMETHEUS_NAMESPACE}" ] && PROM_NAMESPACE="-n ${PROMETHEUS_NAMESPACE} "
[ "${ISSUER}" ] && CERTMGR_ARGS="${ISSUER}"

#******** DEPLOY SCRIPTS ********
printf "** Deploying Nginx Ingress Controller **\n\n"
${DIR}/ingress-controller-deploy.sh $INGRESS_ARGS

printf "** Deploying cert-manager **\n\n"
${DIR}/certmanager-deploy.sh $CERTMGR_ARGS

printf "** Deploying Prometheus Operator **\n\n"
${DIR}/prometheus-deploy.sh $PROM_VALUES $PROM_NAMESPACE

printf "** Deploying Secret Agent Operator **\n\n"
${DIR}/secret-agent.sh install
