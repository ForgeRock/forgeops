#!/usr/bin/env bash
set -e
kubectl apply --filename https://github.com/tektoncd/pipeline/releases/download/v0.10.2/release.yaml #https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
kubectl -n tekton-pipelines wait --for=condition=Ready pod --all

kubectl apply --filename https://github.com/tektoncd/triggers/releases/download/v0.3.1/release.yaml #https://storage.googleapis.com/tekton-releases/triggers/latest/release.yaml
kubectl apply --filename https://github.com/tektoncd/dashboard/releases/download/v0.5.3/tekton-dashboard-release.yaml
kubectl -n tekton-pipelines wait --for=condition=Ready pod --all

echo ""
echo "Installation complete! You can now use tekton pipelines"
