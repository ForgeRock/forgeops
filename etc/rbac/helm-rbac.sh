#!/usr/bin/env bash
# Example of creating a service account for Helm tiller, and giving that account admin privileges.
kubectl -n kube-system create sa tiller
kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller
helm init --service-account tiller
