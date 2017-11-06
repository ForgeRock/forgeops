#!/usr/bin/env bash
# Example of creating a service account for Helm tiller, and giving that account admin privileges.
# Starting minikube with rbac:
# minikube start --extra-config=apiserver.Authorization.Mode=RBAC
kubectl -n kube-system create sa tiller
kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller
helm init --service-account tiller
