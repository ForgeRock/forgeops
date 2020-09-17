#!/usr/bin/env bash

NAME=${NAME:-small}

# Default these values from the users configuration
PROJECT_ID=$(gcloud config list --format 'value(core.project)')
PROJECT=${PROJECT:-$PROJECT_ID}

R=$(gcloud config list --format 'value(compute.region)')
REGION=${REGION:-$R}

ZONE=${ZONE:-"$REGION-a"}

echo "Getting the cluster credentials for $NAME in Zone $ZONE"
gcloud container clusters get-credentials "$NAME" --zone "$ZONE" || exit 1

# Try to release any L4 service load balancers
echo "Cleaning up the ngnix load balancer. Ignore any errors below"
kubectl -n nginx delete deployment --all
kubectl -n nginx delete svc --all
kubectl delete ns nginx

echo "About to delete the cluster in 10 seconds"
sleep 10
# Delete the cluster. Defaults to the current project.
gcloud container clusters delete "$NAME" --zone "$ZONE"