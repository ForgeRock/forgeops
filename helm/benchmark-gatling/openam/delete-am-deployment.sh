#!/usr/bin/env bash
NAMESPACE=benchmark
# Delete all charts
helm delete --purge $(helm list -q --all --namespace=$NAMESPACE)
# Delete all persistent volume claims
kubectl delete pvc --all
# Delete fast storage class we are using for CTS store.
kubectl delete storageclass fast
