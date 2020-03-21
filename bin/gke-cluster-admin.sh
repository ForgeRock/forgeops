#!/usr/bin/env bash
# Unsupported - this is a sample procedure for a GKE cluster to enable
# in-cluster Docker builds using Kaniko.
#
# This is run by a cluster administrator as a one time process.

PROJECT=${GOOGLE_CLOUD_PROJECT:-engineering-devops}

# Needed on GKE to allow you to deploy privileged operators, etc.
kubectl create clusterrolebinding cluster-admin-binding \
  --clusterrole cluster-admin \
  --user "$(gcloud config get-value account)"

# Create a service account for Kaniko to use
SA_NAME=kaniko
SA_ACCOUNT="${SA_NAME}@${PROJECT}.iam.gserviceaccount.com"

gcloud iam service-accounts create "$SA_NAME" \
    --description "Allows kaniko access to push/pull images to gcr.io/$PROJECT" \
    --display-name "$SA_NAME"

# Role binding to enable the Kaniko service account to push/pull images to the GCR
gcloud projects add-iam-policy-binding "${PROJECT}" --memberw=serviceAccount:"${SA_ACCOUNT}" --role roles/storage.admin
gcloud projects add-iam-policy-binding "${PROJECT}" --member=serviceAccount:"${SA_ACCOUNT}" --role roles/storage.objectAdmin
gcloud projects add-iam-policy-binding "${PROJECT}" --member=serviceAccount:"${SA_ACCOUNT}" --role roles/storage.objectCreator

# Create a key for the service account. Downloaded to a file "kaniko-secret"
# Note: You can always regenerate a new service account key without destroying the service account.
mkdir -p tmp
gcloud iam service-accounts keys create tmp/kaniko-secret --iam-account "${SA_ACCOUNT}"
# Use that file to create a K8S secret for kaniko
kubectl delete secret --namespace kaniko kaniko-secret || true
kubectl create secret generic --namespace kaniko kaniko-secret --from-file=tmp/kaniko-secret

echo "WARNIING!!! Protect the secret in the file tmp/kaniko-secret"
echo "   It is a service account with privilege to push images to gcr.io. Do not commit this file to git"

