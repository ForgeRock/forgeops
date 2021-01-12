#!/usr/bin/env bash
# Port forwards to the Tekton dashboard in your cluster

echo "In your browser open http://localhost:9097"
kubectl -n tekton-pipelines port-forward deployment/tekton-dashboard 9097