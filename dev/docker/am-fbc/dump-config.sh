#!/usr/bin/env bash
# Copies the AM config out of the running pod to the tmp/ directory
# Note that tmp/ is in .gitignore, and is not checked in

rm -fr tmp
pod=`kubectl get pod -l app=am -o jsonpath='{.items[0].metadata.name}'`

kubectl cp $pod:/home/forgerock ./tmp
