#!/usr/bin/env bash

NAMESPACE=$1

# Check if -n flag has been included
if [[ $1 != "-n" ]]; then
    NAMESPACE=monitoring
fi

# Remove Prometheus Operator
helm delete --purge ${NAMESPACE}-exporter-forgerock
helm delete --purge ${NAMESPACE}-prometheus-operator
helm delete --purge ${NAMESPACE}-kube-prometheus

# These get left over after the helm delete --purge has completed.
kubectl delete svc alertmanager-operated prometheus-operated --namespace=$NAMESPACE





