#!/usr/bin/env bash

# helm repo add brigade https://azure.github.io/brigade
NAMESPACE=deployment

kubectl config set-context $(kubectl config current-context) --namespace=$NAMESPACE

helm install -n brigade-server brigade/brigade
helm install -n cdtest brigade/brigade-project -f cdtest.yaml

# authorize service accounts
kubectl create clusterrolebinding brigade --clusterrole cluster-admin --serviceaccount="deployment:brigade-worker"
kubectl create clusterrolebinding brigade --clusterrole cluster-admin --serviceaccount="deployment:brigade-server-brigade-vacuum"
kubectl create clusterrolebinding brigade-ctrl --clusterrole cluster-admin --serviceaccount="deployment:brigade-server-brigade-ctrl"


