#!/bin/bash
# Create an nginx ingres. Minikube now bundles the ingress - so you dont need ths
# See https://github.com/kubernetes/ingress

# Create the default HTTP backend.
kubectl create -f default-backend.yaml
#kubectl expose rc default-http-backend --port=80 --target-port=8080 --name=default-http-backend

# Create the custom nginx.
kubectl create -f nginx-conf.yaml

kubectl create -f ingress-gke.yaml



