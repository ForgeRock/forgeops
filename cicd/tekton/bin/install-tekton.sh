#!/usr/bin/env bash
# Installs Tekton into a cluster.
# Consult the tekton documentation at https://tekton.dev/ to verify the install procedure for your environment.
set -e

kubectl apply --filename https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
kubectl -n tekton-pipelines get pods --no-headers=true | awk '!/Completed/{print $1}' | xargs  kubectl wait -n tekton-pipelines pod --for=condition=Ready


kubectl apply --filename https://storage.googleapis.com/tekton-releases/triggers/latest/release.yaml

kubectl apply --filename https://storage.googleapis.com/tekton-releases/dashboard/latest/tekton-dashboard-release.yaml

kubectl -n tekton-pipelines get pods --no-headers=true | awk '!/Completed/{print $1}' | xargs  kubectl wait -n tekton-pipelines pod --for=condition=Ready

kubectl -n tekton-pipelines apply --recursive -f shared/events

kustomize build shared/task | kubectl apply -f -

echo "Reading Kaniko and slack secrets from GCP"
# Secret was created using:
# gcloud secrets create tekton-secrets-all
# gcloud secrets versions add tekton-secrets-all --data-file="tekton-secrets-all.yaml"
gcloud secrets versions access latest --secret="tekton-secrets-all" |  kubectl -n tekton-pipelines apply -f -

# Kaniko secrets created using
# gcloud secrets create kaniko
# gcloud secrets versions add kaniko --data-file=kaniko.yaml
# The kaniko secret is a gcp json service account that has permissions to push/pull from the gcr registry
# See gke-kaniko.sh for an example of how to create the secret
gcloud secrets versions access latest --secret=kaniko |  kubectl -n kaniko apply -f -

# Install additional notification hooks
kubectl -n tekton-pipelines apply -f https://raw.githubusercontent.com/tektoncd/catalog/master/task/send-to-webhook-slack/0.1/send-to-webhook-slack.yaml

echo ""
echo "Installation complete! You can now use tekton pipelines"
