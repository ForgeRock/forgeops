#!/usr/bin/env bash

NAMESPACE=$1

USAGE="Usage: $0 [<namespace>]"

if [[ $1 == "-h" ]];then
    echo $USAGE
    echo "Run $0 with no arguments will default to monitoring namespace"
    echo "Add namespace after $0 to remove from a specific namespace"
    exit
fi

# Default to monitoring namespace if no namespace added
if [[ $# = 0 ]]; then
    NAMESPACE=monitoring
fi

if read -t 15 -p "Removing Prometheus Operator and Grafana from '${NAMESPACE}' namespace in 15 seconds or when enter is pressed...If this is not what you intended, press ctrl-c and run '$0 -h' for guidance";then echo;fi

# Remove Prometheus Operator
helm delete --purge ${NAMESPACE}-forgerock-servicemonitors
helm delete --purge ${NAMESPACE}-prometheus-operator
helm delete --purge ${NAMESPACE}-kube-prometheus

# These get left over after the helm delete --purge has completed.
kubectl delete svc alertmanager-operated prometheus-operated --namespace=$NAMESPACE





