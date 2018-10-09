#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

source "${BASH_SOURCE%/*}/../etc/gke-env.cfg"


# This adds a small nodepool that is non preemtible. Used for services that can't go down (nfs...)
gcloud beta container node-pools delete "pool2-local-storage" \
    --project="${GKE_PROJECT_ID}" \
    --cluster="${GKE_CLUSTER_NAME}"  \
    --zone="${GKE_PRIMARY_ZONE}"

#    --node-taints="preemptible=true:NoSchedule"

