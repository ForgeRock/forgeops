#!/usr/bin/env bash

# Script to deploy Cert-Manager into kube-system namespace.
# Run ./deploy-cert-manager.sh .

PROVIDER=$(kubectl get nodes -o jsonpath={.items[0].spec.providerID} | awk -F: '{print $1}')
if [[ "${PROVIDER}" == "gce" ]]; then
  # Decrypt encoded service account
  ./decrypt.sh ../etc/cert-manager/cert-manager.json
fi

# Create secret so the Cluster Issuer can gain access to CloudDNS
kubectl create secret generic clouddns --from-file=../etc/cert-manager/cert-manager.json -n kube-system

# Check that tiller is running
while true;
do
  STATUS=$(kubectl get pod -n kube-system | grep tiller | awk '{ print $3 }')
  # kubectl get pods returns an empty string if the cluster is not available
  if [ -z ${STATUS} ]
  then
    echo "The cluster is temporarily unavailable..."
  else
    if [ ${STATUS} == "Running" ]
    then
      echo "The tiller pod is available..."
      break
    else
      echo "The tiller pod is not available..."
    fi
  fi
  sleep 5
done

# Deploy Cert Manager Helm chart
helm upgrade -i cert-manager --namespace kube-system stable/cert-manager --version v0.5.0

# Check that cert-manager is up before deploying the cluster-issuer
while true;
do
  STATUS=$(kubectl get pod -n kube-system | grep cert-manager | awk '{ print $3 }')
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
kubectl create -f ../etc/cert-manager/cluster-issuer.yaml -n kube-system

# Delete decrypted service account
rm -f ../etc/cert-manager/cert-manager.json || true
