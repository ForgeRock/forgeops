#!/usr/bin/env bash
# see https://docs.cert-manager.io/en/latest/getting-started/install.html
#
# NOTE: You need to be on kubectl version >= 1.13

kubectl create namespace cert-manager
kubectl label namespace cert-manager certmanager.k8s.io/disable-validation=true
kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.7/deploy/manifests/cert-manager.yaml

# NOTE: To validate instalation follow the "Verifying the installation" section in https://cert-manager.readthedocs.io/en/latest/getting-started/install.html

