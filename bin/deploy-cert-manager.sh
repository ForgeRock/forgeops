#!/usr/bin/env bash

# Script to deploy Cert-Manager into cert-manager namespace.
# Run ./deploy-cert-manager.sh .
#
# NOTE: You need to be on kubectl version >= 1.14

cd "$(dirname "$0")"

printf "\n\nPlease ensure you have the following kubernetes versions to allow for cert-manager to deploy successfully and kubectl to use kustomize integration: \n"
printf "client version >= 1.14 and server version >= 1.13.\n\n"

sleep 5

# Create namespace to run cert-manager in
kubectl create namespace cert-manager

# Disable resource validation on the cert-manager namespace
kubectl label namespace cert-manager certmanager.k8s.io/disable-validation=true

# Install the CustomResourceDefinitions and cert-manager itself
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v0.8.0/cert-manager.yaml


# Allow time for operator to be deployed so CRDs are recognized
echo "Waiting for cert-manager to deploy"
sleep 30

# Deploy base cert manager Issuer
kubectl apply -k ../etc/cert-manager

# This next section deploy the Let's Encrypt (LE) Issuer. This requires
# setup of the LE issuer, including the dns secrets for the dns01 challenge.
# We do not run this unless we are on GKE.
PROVIDER=$(kubectl get nodes -o jsonpath={.items[0].spec.providerID} | awk -F: '{print $1}')
if [[ "${PROVIDER}" == "gce" ]]; then
  echo "Deploying Let's Encrypt Issuer"
  # Decrypt encoded service account that has rights to control our dns for the dns01 challenge.
  ./decrypt.sh ../etc/cert-manager/cert-manager.json

  # Create secret so the Cluster Issuer can gain access to CloudDNS
  kubectl create secret generic clouddns --from-file=../etc/cert-manager/cert-manager.json -n cert-manager

  kubectl apply -n cert-manager -f ../etc/cert-manager/le-issuer.yaml

  # Delete decrypted service account
  rm -f ../etc/cert-manager/cert-manager.json || true
fi