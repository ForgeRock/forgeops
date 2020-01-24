#!/usr/bin/env bash
# Deploys prometheus-operator Helm Chart, kube-prometheus charts and Forgerock metrics which include custom
# endpoints, alerting rules and Grafana dashboards.
# ./deploy-prometheus.sh -n namespace - deploy to different namespace that monitoring.
# ./deploy-prometheus.sh -v values-file - use different custom values file.
# ./deploy-prometheus.sh -d - delete deployment.

# You can deploy your own custom values file by using the -f <values file> flag.
set -oe pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
PROM_VALUES="${DIR}/prometheus-operator.yaml"
GRAFANA_VALUES="${DIR}/grafana.yaml"
VERSION="0.35.0"

USAGE="Usage: $0 [-n <namespace>] [-v <values file>] [-d]"

# Create namespace
create_ns() {
    ns=$(kubectl get namespace | grep monitoring | awk '{ print $1 }' || true)

    if [ -z "${ns}" ]; then
        kubectl create namespace monitoring
    else
        printf "*** monitoring namespace already exists ***\n"
    fi
}

# deploy Prometheus Operator and forgerock metrics
deploy() {
    
    # Add stable repo to helm
    helm repo add stable https://kubernetes-charts.storage.googleapis.com

    helm upgrade -i prometheus-operator stable/prometheus-operator  -f $PROM_VALUES --namespace=$NAMESPACE # --version $VERSION

    sleep 10

    # Install/Upgrade forgerock-servicemonitors
    helm upgrade -i forgerock-metrics ${DIR}/forgerock-metrics --namespace=$NAMESPACE
}

# Delete all
delete() {
    # Delete Prometheus Operator Helm chart
    helm delete prometheus-operator --namespace=$NAMESPACE

    # Delete CRDs
    kubectl delete crd prometheuses.monitoring.coreos.com
    kubectl delete crd prometheusrules.monitoring.coreos.com
    kubectl delete crd servicemonitors.monitoring.coreos.com
    kubectl delete crd podmonitors.monitoring.coreos.com
    kubectl delete crd alertmanagers.monitoring.coreos.com

    # Delete forgerock-metrics Helm chart
    helm delete forgerock-metrics --namespace=$NAMESPACE

    sleep 10

    # Delete monitoring namespace
    kubectl delete ns monitoring
    exit 1
}

# Output help if -h is included
if [[ $1 == "-h" ]];then
    echo $USAGE
    echo "-n <namespace>    namespace"
    echo "-v <values file>  add custom values file for Prometheus operator."
    echo "-d delete Prometheus Operator and Forgerock metrics"
    exit
fi

# Read arguments
while getopts :n:v:d option; do
    case "${option}" in
        n) NAMESPACE=${OPTARG};;
        v) VALUES=${OPTARG};;
        \?) echo "Error: Incorrect usage"
            echo $USAGE
            exit 1;;
    esac
done

## Validate arguments
# Check if -n flag has been included
[[ $1 != "-n" ]] && NAMESPACE=monitoring
# set custom yaml file if not provided with the -f arg
[ $VALUES ] && PROM_VALUES="${DIR}/${VALUES}"
# delete chart if -d select
[[ ${1} =~ "-d" ]] && delete

# Create namespace
create_ns

# Deploy to cluster
deploy
