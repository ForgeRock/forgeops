#!/usr/bin/env bash
set -e
if [ "$#" -ne 1 ]
then
  echo "Need namespace name to install the pipelines in. ./install_tekton.sh nightly"
  exit 1
fi

NAMESPACE=$1
kubectl create namespace nightly || true #create nightly namespace. Ignore if this namespace is already present.
kubectl apply --filename https://github.com/tektoncd/pipeline/releases/download/v0.10.1/release.yaml #https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
kubectl -n tekton-pipelines wait --for=condition=Ready pod --all

kubectl apply --filename https://github.com/tektoncd/triggers/releases/download/v0.2.1/release.yaml #https://storage.googleapis.com/tekton-releases/triggers/latest/release.yaml
kubectl apply --filename https://github.com/tektoncd/dashboard/releases/download/v0.5.1/tekton-dashboard-release.yaml
kubectl -n tekton-pipelines wait --for=condition=Ready pod --all

kubectl -n $NAMESPACE apply -f .
echo ""
echo "Installation complete! You can now use tekton pipelines"
