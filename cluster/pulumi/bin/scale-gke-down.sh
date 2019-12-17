#!/usr/bin/env bash
# Scale a cluster to 0 nodes. Useful to save cost

CLUSTER=$1

if [ -z "$CLUSTER" ]; then
  echo "Usage: $0 cluster-name"
  exit 1
fi

# Find cluster zone
ZONE=$(gcloud container clusters list  --format="csv[no-heading](location)" --filter="name=$CLUSTER")

for pool in $(gcloud container node-pools list --cluster $CLUSTER --zone $ZONE --format="csv[no-heading](name)")
do
  echo "Scaling $pool to 0"
  # Note - --async can not be used as you cant resize two node pools at the same time
  gcloud container clusters resize $CLUSTER --node-pool $pool --zone $ZONE --quiet --num-nodes 0
done


