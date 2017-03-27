#!/usr/bin/env bash

export ZONE=us-central1-f
export CLUSTER_NAME=openam


# 8 cpus, 30 GB of memory
# machine="n1-standard-8"
# 16 cpus, 60 GB,  .80 cents / hour
machine="n1-standard-16"

# notes: ssd disk - .17 / GB / month, about .50 / hour for 2 TB


# Create a large cluster for benchmark testing...
gcloud alpha container clusters create $CLUSTER_NAME --cluster-version v1.6.0-beta.1 \
  --network "default" --num-nodes 1 \
  --enable-kubernetes-alpha \
  --machine-type  ${machine} --zone $ZONE \
  --disable-addons HttpLoadBalancing


#  --disk-size 100
#  --enable-autoscaling --min-nodes=2 --max-nodes=4 \
