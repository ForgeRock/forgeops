#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

source "${BASH_SOURCE%/*}/../etc/gke-env.cfg"


function delete_pool()
{
echo  gcloud beta container node-pools delete "${1}" \
      --project="${GKE_PROJECT_ID}" \
      --cluster="${GKE_CLUSTER_NAME}"  \
      --zone="${GKE_PRIMARY_ZONE}"
}

############################### Main ######################################

choice=${1:-}

if [ $# -lt 1 ] || [ $# -gt 1 ]; then
   echo "Usage: $0 [pool-name]"
   exit 1
fi

delete_pool ${choice}

exit 0


