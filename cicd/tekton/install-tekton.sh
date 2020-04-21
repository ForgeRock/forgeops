#!/usr/bin/env bash
set -e
kubectl apply --filename https://github.com/tektoncd/pipeline/releases/download/v0.11.1/release.yaml #https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
kubectl -n tekton-pipelines wait --for=condition=Ready pod --all

kubectl apply --filename https://github.com/tektoncd/triggers/releases/download/v0.4.0/release.yaml #https://storage.googleapis.com/tekton-releases/triggers/latest/release.yaml
kubectl apply --filename https://github.com/tektoncd/dashboard/releases/download/v0.6.1/tekton-dashboard-release.yaml
kubectl -n tekton-pipelines wait --for=condition=Ready pod --all

kubectl -n tekton-pipelines apply --recursive -f shared/
echo ""
echo "Installation complete! You can now use tekton pipelines"
