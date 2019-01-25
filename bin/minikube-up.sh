#!/usr/bin/env bash
# Script to bring up the environment for minikube

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

cd $DIR

minikube stop 
minikube start --memory 8192 --kubernetes-version v1.13.2

sleep 5
echo "Installing helm"
helm init
helm repo update

sleep 10

# Minikube needs a simplified version of cert manager for issuing CA certs.
echo "Installing cert manager"
helm upgrade -i cert-manager --namespace kube-system stable/cert-manager

# todo: Install istio
