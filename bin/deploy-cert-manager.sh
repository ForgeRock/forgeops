#!/usr/bin/env bash

# Script to deploy Cert-Manager into cert-manager namespace.
# Run ./deploy-cert-manager.sh .
#
# NOTE: You need to be on kubectl version >= 1.13

# Create namespace to run cert-manager in
kubectl create namespace cert-manager

PROVIDER=$(kubectl get nodes -o jsonpath={.items[0].spec.providerID} | awk -F: '{print $1}')
if [[ "${PROVIDER}" == "gce" ]]; then
  # Decrypt encoded service account
  ./decrypt.sh ../etc/cert-manager/cert-manager.json
fi

# Create secret so the Cluster Issuer can gain access to CloudDNS
kubectl create secret generic clouddns --from-file=../etc/cert-manager/cert-manager.json -n cert-manager

# Disable resource validation on the cert-manager namespace
kubectl label namespace cert-manager certmanager.k8s.io/disable-validation=true

# Install the CustomResourceDefinitions and cert-manager itself
kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.7/deploy/manifests/cert-manager.yaml

# Check that cert-manager is up before deploying the cluster-issuer
while true;
do
  STATUS=$(kubectl get pod -n cert-manager | grep cert-manager-webhook | awk '{ print $3 }')
  # kubectl get pods returns an empty string if the cluster is not available
  if [ -z ${STATUS} ]
  then
    echo "The cluster is temporarily unavailable..."
  else
    if [ ${STATUS} == "Running" ]
    then
      echo "The cert-manager pod is available..."
      break
    else
      echo "The cert-manager pod is not available..."
    fi
  fi
  sleep 5
done

# Allow time for operator to be deployed so CRDs are recognized
sleep 5

# Deploy Cluster Issuer
kubectl create -f ../etc/cert-manager/cluster-issuer.yaml -n cert-manager

# Delete decrypted service account
rm -f ../etc/cert-manager/cert-manager.json || true

