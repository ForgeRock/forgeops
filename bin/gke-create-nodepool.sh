#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset


source "${BASH_SOURCE%/*}/../etc/gke-env.cfg"

function local_pool()
{
gcloud beta container node-pools create "local-storage-pool" \
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
}


function cts_pool()
{
gcloud beta container node-pools create "cts-pool" \
    --project="${GKE_PROJECT_ID}" \
    --cluster="${GKE_CLUSTER_NAME}"  \
    --zone="${GKE_PRIMARY_ZONE}" \
    --machine-type="custom-32-65536" \
    --min-cpu-platform="Intel Skylake" \
    --num-nodes="1" \
    --node-labels="usage=cts" \
    --enable-autorepair \
    --enable-autoupgrade \
    --scopes "https://www.googleapis.com/auth/cloud-platform" \
    --disk-type=pd-ssd \
    --disk-size=80
}

#    --node-taints="preemptible=true:NoSchedule"
#    --node-version="${GKE_CLUSTER_VERSION}" \


############################### Main ######################################

choice=${1:-}

case "${choice}" in

      local)
        local_pool
        ;;

      cts)
        cts_pool
        ;; 

      all)
        local_pool
        cts_pool
        ;; 

      *)
        echo "Usage: $0 [pool-type] where pool-type=local or cts or all"
        ;;

esac
