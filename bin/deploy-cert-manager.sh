#!/usr/bin/env bash

# Script to deploy Cert-Manager into kube-system namespace.
# Run ./deploy-cert-manager.sh .

# Decrypt encoded service account
./decrypt.sh ../etc/cert-manager.json

# Create secret so the Cluster Issuer can gain access to CloudDNS
kubectl create secret generic clouddns --from-file=../etc/cert-manager.json -n kube-system

# Need as sometimes tiller is not ready immediately
while :
do
    helm ls >/dev/null 2>&1
    test $? -eq 0 && break
    echo "Waiting on tiller to be ready..."
    sleep 5s
done

# Deploy Cert Manager Helm chart
helm upgrade -i cert-manager --namespace kube-system stable/cert-manager --values ../cert-manager/values.yaml

# Check that cert-manager is up before deploying the cluster-issuer
while true; do
    if [ $(kubectl get pod -n kube-system | grep cert-manager | awk '{ print $3 }') == "Running"  ]; then
        echo "cert-manager is running..."
        break
    else
        echo "cert-manager is still starting up..."
    fi
    sleep 5
done

# Allow time for operator to be deployed so CRDs are recognized
sleep 5

# Deploy Cluster Issuer
kubectl create -f ../cert-manager/cluster-issuer.yaml -n kube-system

# Delete decrypted service account
rm ../etc/cert-manager.json