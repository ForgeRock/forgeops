#!/usr/bin/env bash
# Creates a hybrid cluster for testing. Uses preemptible VMs and auto-scaling.

CLUSTER=openam
NODEPOOL=flexpool
ZONE=us-central1-c

# 2 cpus, 7.5 GB RAM
small="n1-standard-2"
# 8 cpus, 30 GB of memory
medium="n1-standard-8"
# 16 cpus, 60 GB,  .80 cents / hour
# machine="n1-standard-16"


gcloud alpha container clusters create $CLUSTER \
  --network "default" --num-nodes 1 \
  --machine-type  ${small} --zone $ZONE \
  --disk-size 50
#  --enable-autoscaling --min-nodes=1 --max-nodes=4 \


gcloud alpha container node-pools create $NODEPOOL --cluster $CLUSTER --zone $ZONE \
    --machine-type ${medium} --preemptible --disk-size 50 \
    --enable-autoscaling --min-nodes=0 --max-nodes=4

# Create a storage class for SSD
kubectl create -f storage.yaml

helm init

echo "Giving Tiller time to start"
sleep 20



helm install --namespace nginx  --set "controller.service.loadBalancerIP=35.184.100.105" stable/nginx-ingress

