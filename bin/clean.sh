#!/usr/bin/env bash

# Delete PVCs
kubectl delete pvc --all

# Clean up secrets
kubectl get secrets | grep am | kubectl delete secrets $(awk '{ print $1 }')
kubectl get secrets | grep idm | kubectl delete secrets $(awk '{ print $1 }')
kubectl get secrets | grep ds | kubectl delete secrets $(awk '{ print $1 }')
kubectl delete secret truststore platform-ca