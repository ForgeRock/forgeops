#!/usr/bin/env bash

# Script to deploy Cert-Manager into kube-system namespace.
# Run ./deploy-certmanager.sh to deploy with default ca cert.
# Run ./deploy-certmanager.sh -l to deploy with Let's Encrypt Issuer
# Run ./deploy-certmanager.sh -d to delete cert-manager deployment
#
# To be used if namespace gets stuck in 'terminating state'
#kubectl delete apiservice v1beta1.webhook.cert-manager.io
set -oe pipefail

VERSION="v0.13.0"
ISSUER="ca"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Print usage message to screen
usage() {
  printf "Usage: $0 [-l] [-d] \n\n"
  exit 2
}

# Create namespace
create_ns() {
    ns=$(kubectl get namespace | grep cert-manager | awk '{ print $1 }' || true)

    if [ -z "${ns}" ]; then
        kubectl create namespace cert-manager
    else
        printf "*** cert-manager namespace already exists ***\n"
    fi
}

# Check cert-manager status
status() {
    # Check that cert-manager is up before deploying the cluster-issuer
    while true;
    do
        STATUS=($(kubectl get pod -n cert-manager | grep cert-manager | awk '{ print $3 }'))
        # kubectl get pods returns an empty string if the cluster is not available
        if [ -z ${STATUS[0]} ]; then
            echo "The cluster is temporarily unavailable..."
        else
            if [ ${STATUS[0]} = "Running" ]; then
                echo "The cert-manager pod is available..."

                # Verify the webhook endpoint is enabled
                echo "Validating webhook..."
                while true; 
                do
                    ENDPOINT=$(kubectl get endpoints -n cert-manager | grep cert-manager-webhook | awk '{ print $2 }')
                    if [[ "${ENDPOINT}" =~ "<none>" ]]; then
                        sleep 10
                        echo "cert-manager-webhook endpoint not ready. May take 1-2 mins..."
                    else
                        sleep 10
                        echo "cert-manager-webhook endpoint ready."
                        break
                    fi
                done
                break
            else
                echo "The cert-manager pod is not available..."
            fi
        fi
        sleep 5
    done
}

# Deploy cert-manager
deploy() {
    kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/${VERSION}/cert-manager.yaml

    # Check status of cert-manager service and webhookend point.
    status

    # Deploy Issuer.
    kubectl apply -f ${DIR}/files/${ISSUER}-issuer.yaml -n cert-manager

    # Deploy secrets based on the type of Issuer deployed.
    if [[ ${ISSUER} =~ "ca" ]]; then
        kubectl apply -f ${DIR}/secrets/ca-secret.yaml -n cert-manager
    else
        PROVIDER=$(kubectl get nodes -o jsonpath={.items[0].spec.providerID} | awk -F: '{print $1}')
        if [[ "${PROVIDER}" == "gce" ]]; then
            ${DIR}/decrypt.sh ${DIR}/secrets/cert-manager.json
            kubectl create secret generic clouddns --from-file=${DIR}/secrets/cert-manager.json -n cert-manager
        else
            echo "Not deploying to GCE. Create Let's Encrypt Issuer manually"
        fi
    fi
}

# Delete cert-manager and namespace
delete() {
    kubectl delete -f https://github.com/jetstack/cert-manager/releases/download/${VERSION}/cert-manager.yaml
    sleep 30
    kubectl delete ns cert-manager 
    exit 1
}

# Validate arguments".
[ $# -gt 0 ] && [[ ! ${1} =~ ^(-l|-d) ]] && usage
[ $# -gt 0 ] && [[ ${1} =~ "-d" ]] && delete
[ $# -gt 0 ] && [[ ${1} =~ "-l" ]] && ISSUER="le"

# Create namespace if it doesn't exist
create_ns

# Deploy cert-mamager manifests
deploy

# Delete decrypted service account
rm -f ${DIR}/secrets/cert-manager.json || true

