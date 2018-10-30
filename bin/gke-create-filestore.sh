#!/usr/bin/env bash
# Create a Google Cloud FileStore. This is used for DS backup volumes.
# 1TB is the smallest filestore you can create.
# This is a WIP.

set -o errexit
set -o pipefail
set -o nounset

source "${BASH_SOURCE%/*}/../etc/gke-env.cfg"


NETWORK="${GKE_NETWORK_NAME:-default}"

gcloud beta filestore instances create shared-backup \
    --project="${GKE_PROJECT_ID}" \
    --location="${GKE_PRIMARY_ZONE}" \
    --tier=standard \
    --file-share=name="export,capacity=1TB" \
    --network="name=$NETWORK"
