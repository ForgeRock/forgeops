#!/usr/bin/env bash
# Sample script to create IAM roles to read/write to gcs storage
#
# This is run by a cluster administrator as a *one time process*.
# This is used by ds backup/restore samples in this directory. The
# Samples are configured to use GKE workload identity.


PROJECT=${GOOGLE_CLOUD_PROJECT:-engineering-devops}

# Needed on GKE to allow you to deploy privileged operators, etc.
# kubectl create clusterrolebinding cluster-admin-binding \
#   --clusterrole cluster-admin \
#   --user "$(gcloud config get-value account)"

# Create a GCP service account
SA_NAME=ds-backup
SA_ACCOUNT="${SA_NAME}@${PROJECT}.iam.gserviceaccount.com"

gcloud iam service-accounts create "$SA_NAME" \
    --description "Allows export and import of ldif files for gcr.io/$PROJECT. Created by Warren" \
    --display-name "$SA_NAME"

# Role binding to enable the service account to push/pull images to the GCR
gcloud projects add-iam-policy-binding "${PROJECT}" --member=serviceAccount:"${SA_ACCOUNT}" --role roles/storage.admin
gcloud projects add-iam-policy-binding "${PROJECT}" --member=serviceAccount:"${SA_ACCOUNT}" --role roles/storage.objectAdmin
gcloud projects add-iam-policy-binding "${PROJECT}" --member=serviceAccount:"${SA_ACCOUNT}" --role roles/storage.objectCreator


# The command below needs to be run for each namespace!
# This creates the mapping between the GCP service account and the Kubernetes service account
NAMESPACE=warren
KSA_NAME=ds-backup
gcloud iam service-accounts add-iam-policy-binding \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:${PROJECT}.svc.id.goog[${NAMESPACE}/${KSA_NAME}]" \
  $SA_ACCOUNT

# If you do not want to use workload identity, you can also create a service account.json
# See the comments in the gcs.yaml
# Uncomment this below

# mkdir -p tmp
# gcloud iam service-accounts keys create tmp/service-account.json --iam-account "${SA_ACCOUNT}"
# # Use that file to create a K8S secret for kaniko
# kubectl delete secret gcs-secret || true
# kubectl create secret generic gcs-secret --from-file=tmp/service-account.json

