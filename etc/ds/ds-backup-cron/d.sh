#!/usr/bin/env bash

kustomize  build . | kubectl delete  -f -

kubectl delete job,cronjob --all
kubectl delete pvc  data-ds-idrepo-0-clone

kubectl delete volumesnapshot --all
