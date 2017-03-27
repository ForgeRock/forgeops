#!/usr/bin/env bash

export ZONE=us-central1-f
export CLUSTER_NAME=openam


# 8 cpus, 30 GB of memory
# machine="n1-standard-8"
# 16 cpus, 60 GB
machine="n1-standard-16"

# Create a large cluster for benchmark testing...
# The --local-ssd-count opton will create /mnt/disks/ssd{0,1,..}
gcloud alpha container clusters create $CLUSTER_NAME \
  --local-ssd-count 1 \
  --network "default" --num-nodes 2 \
  --enable-kubernetes-alpha \
  --machine-type  ${machine} --zone $ZONE \
  --disable-addons HttpLoadBalancing

#  Other options you might want:
#  --disk-size 100
#  --enable-autoscaling --min-nodes=2 --max-nodes=4 \
