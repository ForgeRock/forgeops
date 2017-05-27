#!/usr/bin/env bash
# Set the default Kubernetes namespace context. This causes any helm or kubectl commands to target
# the configured namespace

NS=${1:-default}

echo Setting namespace to $NS

echo kubectl config set-context $(kubectl config current-context) --namespace=${NS}

kubectl config set-context $(kubectl config current-context) --namespace=${NS}

echo "If you are using git ssh creds, don't forget to run bin/setup-git-creds.sh"
