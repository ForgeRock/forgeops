#!/usr/bin/env bash

export ZONE=us-central1-f
export CLUSTER_NAME=openam


# 8 cpus, 30 GB of memory
machine="n1-standard-8"
# 16 cpus, 60 GB,  .80 cents / hour
# machine="n1-standard-16"

# Benchmark notes: SSD disk - .17 / GB / month, about .50 / hour for 2 TB
# scopes storage-full is needed for container engine to run the gsutil command. We use this for dj backup.
# Create an alpha cluster
gcloud alpha container clusters create $CLUSTER_NAME --cluster-version 1.6.1 \
  --network "default" --num-nodes 1 \
  --enable-kubernetes-alpha \
  --enable-autoscaling --min-nodes=1 --max-nodes=4 \
  --scopes storage-full \
  --machine-type  ${machine} --zone $ZONE \
  
# Options we no longer use...
#  --disable-addons HttpLoadBalancing
#  --disk-size 100

kubectl create -f storage.yaml

helm init

cd ../ingress
#./create-nginx-ingress.sh 



