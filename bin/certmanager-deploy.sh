#!/usr/bin/env bash

# Script to deploy Cert-Manager into kube-system namespace.
# Run ./certmanager-deploy.sh to deploy with default ca cert.
# Run ./certmanager-deploy.sh -l to deploy with Let's Encrypt Issuer
# Run ./certmanager-deploy.sh -d to delete cert-manager deployment
#
# To be used if namespace gets stuck in 'terminating state'
#kubectl delete apiservice v1beta1.webhook.cert-manager.io
set -oe pipefail

VERSION="v0.14.1"
ISSUER="ca"
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
CM_DIR="${CURRENT_DIR}/../cluster/addons/certmanager"

# Print usage message to screen
usage() {
  printf "Usage: $0 [-l] [-d] \n\n"
  exit 2
}

# Deploy cert-manager
deploy() {

    # Deploy manifests
    kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/${VERSION}/cert-manager.yaml

    # Wait for webhook deployment to be ready
    kubectl wait --for=condition=available deployment/cert-manager-webhook --timeout=300s -n cert-manager

    # Deploy Issuer.
    kubectl apply -f ${CM_DIR}/files/${ISSUER}-issuer.yaml -n cert-manager

    # Deploy secrets based on the type of Issuer deployed.
    if [[ ${ISSUER} =~ "ca" ]]; then
        kubectl apply -f ${CM_DIR}/secrets/ca-secret.yaml -n cert-manager
    else
        PROVIDER=$(kubectl get nodes -o jsonpath={.items[0].spec.providerID} | awk -F: '{print $1}')
        if [[ "${PROVIDER}" == "gce" ]]; then
            ${CM_DIR}/decrypt.sh ${CM_DIR}/secrets/cert-manager.json
            kubectl create secret generic clouddns --from-file=${CM_DIR}/secrets/cert-manager.json -n cert-manager
        else
            echo "Not deploying to GCE. Create Let's Encrypt Issuer manually"
        fi
    fi
}

# Delete cert-manager and namespace
delete() {
    kubectl delete -f https://github.com/jetstack/cert-manager/releases/download/${VERSION}/cert-manager.yaml

    exit 1
}

# Validate arguments".
[ $# -gt 0 ] && [[ ! ${1} =~ ^(-l|-d) ]] && usage
[ $# -gt 0 ] && [[ ${1} =~ "-d" ]] && delete
[ $# -gt 0 ] && [[ ${1} =~ "-l" ]] && ISSUER="le"

# Deploy cert-mamager manifests
deploy

# Delete decrypted service account
rm -f ${CM_DIR}/secrets/cert-manager.json || true

