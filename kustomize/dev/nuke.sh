#!/usr/bin/env bash

kubectl delete -f dist/quickstart.yaml --ignore-not-found=true
kubectl delete pvc --all

