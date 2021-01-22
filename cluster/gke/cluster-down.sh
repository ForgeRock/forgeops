#!/usr/bin/env bash

NAME=${NAME:-small}

# Default these values from the users configuration
PROJECT_ID=$(gcloud config list --format 'value(core.project)')
PROJECT=${PROJECT:-$PROJECT_ID}

# Static IP values for deletion
DELETE_STATIC_IP="${DELETE_STATIC_IP:-false}"
STATIC_IP_NAME="${STATIC_IP_NAME:-$NAME}"

R=$(gcloud config list --format 'value(compute.region)')
REGION=${REGION:-$R}

ZONE=${ZONE:-"$REGION-a"}


echo "About to delete the cluster $NAME in zone $ZONE, and ALL data. Press any key to continue, or control-c to quit"
read;



echo "Getting the cluster credentials for $NAME in Zone $ZONE"
gcloud container clusters get-credentials "$NAME" --zone "$ZONE" || exit 1

echo "About to delete the cluster in 10 seconds. YOU WILL LOSE ALL DATA! Control-c now to stop this"

sleep 10

# Try to release any L4 service load balancers
echo "Cleaning up the ngnix load balancer. Ignore any errors below"
kubectl -n nginx delete deployment --all
kubectl -n nginx delete svc --all
kubectl delete ns nginx


echo "Deleting all PVC disks in 5 seconds... YOU WILL LOSE ALL DATA. Control-c now to stop this"
sleep 5
kubectl delete pvc --all-namespaces --all

sleep 10
# Delete the cluster. Defaults to the current project.
gcloud container clusters delete "$NAME" --zone "$ZONE"

# Delete static ip if $DELETE_STATIC_IP set to true
if [ "$DELETE_STATIC_IP" == true ]; then
  echo "Deleting static IP ${STATIC_IP_NAME}..."
  gcloud compute addresses delete "$STATIC_IP_NAME" --project "$PROJECT" --region "$REGION"
fi

echo "Check your GCP console for any orphaned project resources such as disks!"