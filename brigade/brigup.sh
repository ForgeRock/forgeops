#!/usr/bin/env bash

BRIG_HOME=/Users/warren.strange/src/go/src/github.com/Azure/brigade

# helm repo add brigade https://azure.github.io/brigade

#helm install -n brigade -f values.yaml $BRIG_HOME/charts/brigade
helm install -n brigade -f values.yaml brigade/brigade
helm install -n forgerock-cdtest -f brigade.yaml brigade/brigade-project

# Needed so brigade worker can complete OK and can run things like helm
# See https://github.com/Azure/brigade/issues/247
kubectl create clusterrolebinding brigade --clusterrole cluster-admin --serviceaccount="default:brigade-worker"

echo "Run with "
echo "brig run -f brigade.js forgerock/cdtest"


# k delete secret -l heritage=brigade
# k delete secret -l jobname=helm
