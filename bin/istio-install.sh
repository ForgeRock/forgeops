#!/usr/bin/env bash
#  *Demo* script to install istio. Please review the instructions 
# at https://istio.io/docs/setup/kubernetes/quick-start/ 
#

# Run this relative to current directory
mkdir -p tmp

cd tmp

echo "Downloading istio"
curl -L https://git.io/getLatestIstio | sh -

echo "Installing istio"

cd istio-*

echo "Install CRDs"
kubectl apply -f install/kubernetes/helm/istio/templates/crds.yaml

sleep 10

echo "Install istio CRD"
kubectl apply -f install/kubernetes/istio-demo.yaml


echo "Done. Istio files are in $PWD"
