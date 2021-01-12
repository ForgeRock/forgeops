#!/usr/bin/env bash


for c in amster am idm dev-base
do
    kustomize build "$c" | kubectl delete -f -
done

kubectl delete pvc --all

