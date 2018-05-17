#!/usr/bin/env bash

USAGE="Usage: $0: [-G | -P] [-n <namespace>] [-p <port>]"

if [ $# -lt 1 ] || [ $1 == "-h" ];then
    echo "Usage: $0 [-G | -P] -n <namespace>\n"
    echo "-G                port-forward to Grafana"
    echo "-P                port-forward to Prometheus"
    echo "-n <namespace>    namespace"
    echo "-p <port>         port"
    exit
fi

while getopts :GPn:p: option; do
    case "${option}" in
        G) GRAFANA=1;;
        P) PROMETHEUS=1;;
        n) NAMESPACE=${OPTARG};;
        p) PORT=${OPTARG};;
        \?) echo "Error: Incorrect usage"
            echo $USAGE
            exit 1;;
    esac
done

if [[ $2 != "-n" ]]; then
    NAMESPACE=monitoring
fi

# Check if both optional flags have been included
if [[ $GRAFANA -eq 1 ]] && [[ $PROMETHEUS -eq 1 ]]; then
    echo "Invalid choice: Must select EITHER option -g to connect to Grafana or -p to to connect to Prometheus"
    echo $USAGE
    exit 1
fi

# Port forward to Grafana
if [[ $GRAFANA -eq 1 ]]; then
    # check to see if port arg was set
    if ! [[ $PORT ]]; then
        PORT=3000
    fi

    kubectl port-forward $(kubectl get  pods --selector=app=${NAMESPACE}-kube-prometheus-grafana --output=jsonpath="{.items..metadata.name}")  $PORT:3000 --namespace=$NAMESPACE
fi

# Port forward to Grafana
if [[ $PROMETHEUS -eq 1 ]]; then
    # check to see if port arg was set
    if ! [[ $PORT ]]; then
        PORT=9090
    fi

    kubectl port-forward  prometheus-${NAMESPACE}-kube-prometheus-prometheus-0 $PORT:9090 --namespace=$NAMESPACE
fi

echo "Incorrect usage: "
echo $USAGE
