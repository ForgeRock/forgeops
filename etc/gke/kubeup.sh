#!/bin/bash
# Sample convenience script to start a cluster, register docker credentials, create the ingress. etc.

# We are creating images from gcr - so we don't need this right now.
#../helm/bin/registry.sh

# Create a default storage class for SSD
kubectl create -f storage.yaml
cd ../ingress
./create-nginx-ingress.sh
./ddclient.sh
cd ../helm
helm init

echo "Ready"
