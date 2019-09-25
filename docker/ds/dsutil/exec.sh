#!/usr/bin/env bash
# just execs into the dsutil pod

pod=`kubectl get pod -l app=dsutil -o jsonpath='{.items[0].metadata.name}'`
kubectl exec $pod -it bash
