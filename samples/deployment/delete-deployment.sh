#!/usr/bin/env bash

NAMESPACE=bench
# Delete all charts
helm delete --purge $(helm list -q --all --namespace=$NAMESPACE)

# Delete all persistent volume claims
kubectl delete pvc --all
