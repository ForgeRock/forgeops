#!/usr/bin/env bash
# Clean up old job pods

kubectl --namespace tekton-pipelines delete pod --field-selector=status.phase==Failed
kubectl --namespace tekton-pipelines delete pod --field-selector=status.phase==Succeeded