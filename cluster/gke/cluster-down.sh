#!/usr/bin/env bash

NAME=${NAME:-small}

# Default these values from the users configuration
PROJECT_ID=$(gcloud config list --format 'value(core.project)')
PROJECT=${PROJECT:-$PROJECT_ID}

R=$(gcloud config list --format 'value(compute.region)')
REGION=${REGION:-$R}

ZONE=${ZONE:-"$REGION-a"}

# Delete the cluster. Defaults to the current project.
gcloud container clusters delete $NAME --zone "$ZONE"