#!/usr/bin/env bash
set -e
if [ "$#" -ne 1 ]
then
  echo "Need namespace name to install the pipelines in. ./install_tekton.sh smoke"
  exit 1
fi

NAMESPACE=$1
kubectl create namespace $NAMESPACE || true #create $NAMESPACE namespace. Ignore if this namespace is already present.
kubectl -n tekton-pipelines wait --for=condition=Ready pod --all

kubectl -n $NAMESPACE apply -f .
kubectl -n $NAMESPACE apply -f ../shared/tasks/deploy-images-task.yaml
kubectl -n $NAMESPACE apply -f ../shared/tasks/build-images-task.yaml
echo ""
echo "Installation complete! You can now use the $NAMESPACE pipeline"

