#!/usr/bin/env bash
# Utility to see logs from gatling init container when tests are running
POD_NAME=$(kubectl get pod --selector=app=forgeops-benchmark \
  -o jsonpath='{.items[*].metadata.name}')
CONTAINER_NAME=forgeops-benchmark-gatling
kubectl logs -f $POD_NAME -c $CONTAINER_NAME
