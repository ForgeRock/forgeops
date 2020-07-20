#!/usr/bin/env bash

echo "In your browser open http://localhost:9097"
kubectl -n tekton-pipelines port-forward deployment/tekton-dashboard 9097