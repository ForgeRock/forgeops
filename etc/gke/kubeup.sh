#!/bin/bash
# Sample convenience script to start a cluster, register docker credentials, create the ingress. etc.
./create-cluster.sh 
../helm/bin/registry.sh
kubectl create -f storage.yaml
cd ../ingress
./create-nginx-ingress.sh
./ddclient.sh
cd ../helm
helm init

echo "Ready"
