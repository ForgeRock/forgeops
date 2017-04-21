#!/usr/bin/env bash

export ZONE=us-central1-f
export CLUSTER_NAME=openam


# 8 cpus, 30 GB of memory
# machine="n1-standard-8"
# 16 cpus, 60 GB,  .80 cents / hour
machine="n1-standard-8"

# notes: ssd disk - .17 / GB / month, about .50 / hour for 2 TB



# Create a large cluster for benchmark testing...
gcloud alpha container clusters create $CLUSTER_NAME --cluster-version 1.6.1 \
  --network "default" --num-nodes 1 \
  --enable-kubernetes-alpha \
  --enable-autoscaling --min-nodes=1 --max-nodes=4 \
  --machine-type  ${machine} --zone $ZONE \
  
# Options we no longer use...
#  --disable-addons HttpLoadBalancing
#  --disk-size 100
#  --enable-autoscaling --min-nodes=2 --max-nodes=4 \

kubectl create -f storage.yaml

helm init

cd ../ingress
./create-nginx-ingress.sh 



