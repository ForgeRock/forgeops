#!/usr/bin/env bash
# Set the default Kubernetes namespace context. This causes any helm or kubectl commands to target
# the configured namespace

NS=${1:-default}

echo Setting namespace to $NS

echo kubectl config set-context $(kubectl config current-context) --namespace=${NS}

kubectl config set-context $(kubectl config current-context) --namespace=${NS}
