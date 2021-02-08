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


echo "The \"${NAME}\" cluster will be deleted. This action cannot be undone."
echo "Press any key to continue, or CTRL+C to quit"
read;

echo "Getting the cluster credentials for $NAME in Zone $ZONE"
gcloud container clusters get-credentials "$NAME" --zone "$ZONE" || exit 1


read -r -p "Do you want to delete all PVCs allocated by this cluster (recommended for dev clusters)? [Y/N] " response
case "$response" in
    [nN][oO]|[nN]) 
        echo
        echo "***The following PVCs will not be removed. You're responsible to remove them later***"
        kubectl get pvc --all-namespaces --no-headers
        ;;
    [yY][eE][sS]|[yY]) 
        echo
        echo "***Draining all nodes***"
        kubectl cordon -l forgerock.io/cluster
        kubectl delete pod --all-namespaces --all --grace-period=0
        echo
        echo "***Deleting all PVCs***"
        kubectl delete pvc --all-namespaces --all
        ;;
    *)
        echo "Invalid option. Please try again."
        exit 1
        ;;
esac

# Attempt to release any L4 service load balancers
echo 
echo "***Cleaning all services and load balancers if any***"
kubectl delete svc --all --all-namespaces

# Delete the cluster. Defaults to the current project.
gcloud container clusters delete --quiet "$NAME" --zone "$ZONE"

# Delete static ip if $DELETE_STATIC_IP set to true
if [ "$DELETE_STATIC_IP" == true ]; then
  echo "Deleting static IP ${STATIC_IP_NAME}..."
  gcloud compute addresses delete --quiet "$STATIC_IP_NAME" --project "$PROJECT" --region "$REGION"
fi

echo "Check your GCP console for any orphaned project resources such as disks!"