#!/usr/bin/env bash

# Script to deploy Cert-Manager into kube-system namespace.
# Run ./deploy-cert-manager.sh .

# Decrypt encoded service account
./decrypt.sh ../etc/cert-manager.json

# Create secret so the Cluster Issuer can gain access to CloudDNS
kubectl create secret generic clouddns --from-file=../etc/cert-manager.json -n kube-system

# Deploy Cert Manager Helm chart
helm upgrade -i cert-manager --namespace kube-system stable/cert-manager --values ../cert-manager/values.yaml

# Deploy Cluster Issuer
kubectl create -f ../cert-manager/cluster-issuer.yaml -n kube-system

# Delete decrypted service account
rm ../etc/cert-manager.json