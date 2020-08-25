#!/usr/bin/env bash
# Scale a cluster (default 0). Useful to save cost or spin a cluster back up

CLUSTER=$1

if [ -z "$CLUSTER" ]; then
  echo "Usage: $0 cluster-name  [number of nodes - default 0]"
  exit 1
fi

NODES="${2:-0}"
# DS node pool size is twice as large. Yes this is a nasty hack.
DS_NODES=$((2*$NODES))

# Find cluster zone
ZONE=$(gcloud container clusters list  --format="csv[no-heading](location)" --filter="name=$CLUSTER")

for pool in $(gcloud container node-pools list --cluster $CLUSTER --zone $ZONE --format="csv[no-heading](name)")
do
  # Note - --async can not be used as you cant resize two node pools at the same time
  nodes="$NODES"
  if [ "$pool" == "ds-pool" ]; then
      nodes="$DS_NODES"
  fi
  echo "Scaling $pool to $nodes"
  gcloud container clusters resize $CLUSTER --node-pool $pool --zone $ZONE --quiet --num-nodes "$nodes"
done

