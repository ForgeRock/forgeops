#!/usr/bin/env bash

kubectl create secret generic clouddns --from-file=../cert-manager/key.json -n kube-system
helm upgrade -i cert-manager --namespace kube-system stable/cert-manager --values ../cert-manager/values.yaml
kubectl create -f ../cert-manager/cluster-issuer.yaml -n kube-system