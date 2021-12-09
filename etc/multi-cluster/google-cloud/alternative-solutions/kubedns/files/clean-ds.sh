#! /bin/bash

# multi-cluster DS: script to clean DS CTS and DS IDREPO from US and Europe clusters
# Usage: ./clean-ds.sh us-gke-context europe-gke-context namespace

NAMESPACE=${1:-multi-cluster}
US_CONTEXT=${2:-gke_engineering-devops_us-west2-a_ds-wan-replication-us}
EUROPE_CONTEXT=${3:-gke_engineering-devops_europe-west2-b_ds-wan-replication}

echo ""
echo "Cleaning US cluster"
kubectx $US_CONTEXT
kubens $NAMESPACE
skaffold delete --profile multi-cluster-ds-us
kubectl delete pvc data-ds-idrepo-0
kubectl delete pvc data-ds-idrepo-1
kubectl delete pvc data-ds-cts-0
kubectl delete pvc data-ds-cts-1

echo ""
echo "Cleaning Europe cluster"
kubectx $EUROPE_CONTEXT
kubens $NAMESPACE
skaffold delete --profile multi-cluster-ds-eu
kubectl delete pvc data-ds-idrepo-0
kubectl delete pvc data-ds-idrepo-1
kubectl delete pvc data-ds-cts-0
kubectl delete pvc data-ds-cts-1
