#!/usr/bin/env bash
# Create a Google Cloud FileStore. This is used for DS backup volumes.
# 1TB is the smallest filestore you can create.
# This is a WIP.
source etc/gke-env.cfg 

NETWORK="${GKE_NETWORK_NAME:-default}"

gcloud beta filestore instances create shared-backup \
    --project=engineering-devops \
    --location=us-central1-c \
    --tier=standard \
    --file-share=name="export,capacity=1TB" \
    --network="name=$NETWORK"