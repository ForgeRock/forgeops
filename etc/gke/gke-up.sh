#!/usr/bin/env bash
# Sample script to initialize GKE. This creates the cluster and configures Helm, the nginx ingress, and 
# creates git credential secrets. Edit this for your requirements.
./create-cluster.sh

kubectl create -f storage.yaml

helm init

../ingress/create-nginx-ingress.sh 

../../bin/setup-git-creds.sh

