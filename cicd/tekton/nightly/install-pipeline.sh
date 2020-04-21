#!/usr/bin/env bash
set -e
if [ "$#" -ne 1 ]
then
  echo "No namespace was provided. Installing pipeline in 'tekton-pipelines'"
  echo "If you want to install the pipeline in a different namespace, run: ./install_pipeline.sh NAMESPACE"
fi

NAMESPACE="${1:-tekton-pipelines}"
kubectl create namespace $NAMESPACE || true #create $NAMESPACE namespace. Ignore if this namespace is already present.
kubectl -n tekton-pipelines wait --for=condition=Ready pod --all

kubectl -n $NAMESPACE apply -f .
echo ""
echo "Installation complete! You can now use the $NAMESPACE pipeline"
