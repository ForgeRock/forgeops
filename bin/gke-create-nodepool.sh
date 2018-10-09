#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

source "${BASH_SOURCE%/*}/../etc/gke-env.cfg"


# This adds a small nodepool that is non preemtible. Used for services that can't go down (nfs...)
gcloud beta container node-pools create "pool2-local-storage" \
    --project="${GKE_PROJECT_ID}" \
    --cluster="${GKE_CLUSTER_NAME}"  \
    --zone="${GKE_PRIMARY_ZONE}" \
    --machine-type="custom-8-24576" \
    --min-cpu-platform="Intel Skylake" \
    --num-nodes="1" \
    --node-labels="disk=local-nvme" \
    --enable-autorepair \
    --enable-autoupgrade \
    --scopes "https://www.googleapis.com/auth/cloud-platform" \
    --disk-type=pd-ssd \
    --local-ssd-count 1


#    --node-taints="preemptible=true:NoSchedule"
#    --node-version="${GKE_CLUSTER_VERSION}" \

