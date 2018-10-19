#!/usr/bin/env bash
# Deploys prometheus-operator Helm Chart, kube-prometheus charts and Forgerock metrics which include custom
# endpoints, alerting rules and Grafana dashboards.
# Script deploys to monitoring namespace by default but can be override by -n <namespace flag>

# kube-prometheus and prometheus-operator Helm charts use values files provided in ../etc/prometheus-values. 
# The kube-prometheus.yaml file provides configuration values for Prometheus and Alertmanager. These can be overriden by providing
# the path to your own copy of the file using the -k <values file> flag.

# forgerock-metrics uses ../etc/prometheus-values/custom.yaml which can be used to override the forgerock-metrics Helm chart values.
# You can deploy your own custom values file by using the -f <values file> flag.

MONPATH="../etc/prometheus-values"
DEFAULT_VALUES="${MONPATH}/kube-prometheus.yaml"

USAGE="Usage: $0 [-n <namespace>] [-f <values file>] [-k <kube-prometheus values file>]"

# Output help if no arguments or -h is included
if [[ $1 == "-h" ]];then
    echo $USAGE
    echo "-n <namespace>    namespace"
    echo "-f <values file>  add custom values file for forgerocks-metrics. Default: custom.yaml"
    echo "-k <values file>  add custom values file for kube-prometheus. Default: etc/kube-prometheus.yaml"
    exit
fi

# Read arguments
while getopts :n:f:k: option; do
    case "${option}" in
        n) NAMESPACE=${OPTARG};;
        f) FILE=${OPTARG};;
        k) KFILE=${OPTARG};;
        \?) echo "Error: Incorrect usage"
            echo $USAGE
            exit 1;;
    esac
done

# Check if -n flag has been included
if [[ $1 != "-n" ]]; then
    NAMESPACE=monitoring
fi

# set custom yaml file if not provided with the -f arg
if [ $FILE ]; then
    CUSTOM_FILE="--values ${MONPATH}/${FILE}"
fi

# assign kube-prometheus override file if provided as -k arg. 
if [ $KFILE ]; then
    OVERRIDE_VALUES="-f ${KFILE}"
fi

# Deploy to cluster
if read -t 10 -p "Installing Prometheus Operator and Grafana to '${NAMESPACE}' namespace in 10 seconds or when enter is pressed...";then echo;fi

# Add coreos repo to helm
helm repo add coreos https://s3-eu-west-1.amazonaws.com/coreos-charts/stable/

# Install/Upgrade prometheus-operator
helm upgrade -i ${NAMESPACE}-prometheus-operator coreos/prometheus-operator --set=rbac.install=true --values ${MONPATH}/prometheus-operator.yaml --namespace=$NAMESPACE

# Install/Upgrade kube-prometheus
helm upgrade -i ${NAMESPACE}-kube-prometheus coreos/kube-prometheus --set=rbac.install=true -f $DEFAULT_VALUES $OVERRIDE_VALUES --namespace=$NAMESPACE

# Install/Upgrade forgerock-servicemonitors
helm upgrade -i ${NAMESPACE}-forgerock-metrics ../helm/forgerock-metrics $CUSTOM_FILE --set=rbac.install=true --namespace=$NAMESPACE
