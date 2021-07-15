#!/usr/bin/env bash
# A sample script to install Velero on GCP. Edit this for your environment.
set -x

BUCKET=${BUCKET:-forgeops-velero}
NAMESPACE=velero
# Kubernetes service account name
KSA_NAME=velero

gsutil mb gs://$BUCKET

PROJECT=$(gcloud config get-value project)

# GCP Service Account name
SA_NAME=velero
SA_ACCOUNT="${SA_NAME}@${PROJECT}.iam.gserviceaccount.com"

gcloud iam service-accounts create $SA_NAME \
    --display-name "Velero service account"


ROLE_PERMISSIONS=(
    compute.disks.get
    compute.disks.create
    compute.disks.createSnapshot
    compute.snapshots.get
    compute.snapshots.create
    compute.snapshots.useReadOnly
    compute.snapshots.delete
    compute.zones.get
)

gcloud iam roles create velero.server \
    --project $PROJECT \
    --title "Velero Server" \
    --permissions "$(IFS=","; echo "${ROLE_PERMISSIONS[*]}")"

gcloud projects add-iam-policy-binding $PROJECT \
    --member serviceAccount:$SA_ACCOUNT \
    --role projects/$PROJECT/roles/velero.server

gsutil iam ch serviceAccount:$SA_ACCOUNT:objectAdmin gs://${BUCKET}

gcloud iam service-accounts keys create credentials-velero \
    --iam-account $SA_ACCOUNT

# Optional - set workload identity

gcloud iam service-accounts add-iam-policy-binding \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:${PROJECT}.svc.id.goog[${NAMESPACE}/${KSA_NAME}]" \
  $SA_ACCOUNT


# You can repeat this command below in another cluster to create a second DR cluster.
velero install \
    --provider gcp \
    --plugins velero/velero-plugin-for-gcp:v1.2.0 \
    --bucket $BUCKET \
    --secret-file ./credentials-velero

# Add an annotation for the CSI driver to mark it for use with Velero.
kubectl annotate storageclass standard-rwo  velero.io/csi-volumesnapshot-class="true"
