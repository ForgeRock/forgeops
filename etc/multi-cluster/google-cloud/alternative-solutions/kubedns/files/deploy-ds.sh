#! /bin/bash

# multi-cluster DS: script to deploy DS CTS and DS IDREPO to US and Europe clusters
# Usage: ./deploy-ds.sh us-gke-context europe-gke-context namespace

NAMESPACE=${1:-multi-cluster}
US_CONTEXT=${2:-gke_engineering-devops_us-west2-a_ds-wan-replication-us}
EUROPE_CONTEXT=${3:-gke_engineering-devops_europe-west2-b_ds-wan-replication}

echo "multi-cluster DS deployment to GKE"
echo "Using the following values:"
echo " - US GKE context: $US_CONTEXT"
echo " - Europe GKE context: $EUROPE_CONTEXT"
echo " - Namespace: $NAMESPACE"

echo
echo "-----"
echo "Deploying DS to US cluster"
kubectx $US_CONTEXT
kubens $NAMESPACE || (kubectl create namespace $NAMESPACE && kubens $NAMESPACE)
skaffold run --profile multi-cluster-ds-us

echo
echo "-----"
echo "Deploying DS to EUROPE cluster"
kubectx $EUROPE_CONTEXT
kubens $NAMESPACE || (kubectl create namespace $NAMESPACE && kubens $NAMESPACE)
skaffold run --profile multi-cluster-ds-eu
