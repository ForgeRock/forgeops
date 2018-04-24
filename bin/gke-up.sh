#!/usr/bin/env bash
# Sample wrapper script to initialize GKE. This creates the cluster and configures Helm, the nginx ingress,
# and creates git credential secrets. Edit this for your requirements.

./create-cluster.sh
./create-sc.sh
./create-ns.sh
./helm-rbac-init.sh
./create-secrets.sh
./gke-ingress.sh