#!/usr/bin/env bash

NAMESPACE=deployment

kubectl config set-context $(kubectl config current-context) --namespace=$NAMESPACE

helm delete --purge brigade-server
helm delete --purge cdtest

kubectl delete job --all
kubectl delete pods --all

# afdf
echo "hello"