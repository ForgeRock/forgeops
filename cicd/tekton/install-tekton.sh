#!/usr/bin/env bash
set -e
kubectl apply --filename https://github.com/tektoncd/pipeline/releases/download/v0.11.1/release.yaml #https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
kubectl -n tekton-pipelines get pods --no-headers=true | awk '!/Completed/{print $1}' | xargs  kubectl wait -n tekton-pipelines pod --for=condition=Ready

kubectl apply --filename https://github.com/tektoncd/triggers/releases/download/v0.4.0/release.yaml #https://storage.googleapis.com/tekton-releases/triggers/latest/release.yaml
kubectl apply --filename https://github.com/tektoncd/dashboard/releases/download/v0.6.1/tekton-dashboard-release.yaml
kubectl -n tekton-pipelines get pods --no-headers=true | awk '!/Completed/{print $1}' | xargs  kubectl wait -n tekton-pipelines pod --for=condition=Ready

kubectl -n tekton-pipelines apply --recursive -f shared/
echo ""
echo "Installation complete! You can now use tekton pipelines"
