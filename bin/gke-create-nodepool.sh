#!/usr/bin/env bash

. ../etc/gke-env.cfg

# This adds a small nodepool that is non preemtible. Used for services that can't go down (nfs...)
gcloud beta container node-pools create "${GKE_CLUSTER_NAME}-pool1" \
    --cluster="${GKE_CLUSTER_NAME}"  \
    --zone="${GKE_PRIMARY_ZONE}" \
    --machine-type="n1-standard-1" \
    --num-nodes="1" \
    --enable-autorepair \
    --node-version="${GKE_CLUSTER_VERSION}" \
    --scopes "https://www.googleapis.com/auth/cloud-platform" \
    --node-taints="preemptible=true:NoSchedule"