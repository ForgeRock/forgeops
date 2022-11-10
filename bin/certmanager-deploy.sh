#!/usr/bin/env bash

# Script to deploy Cert-Manager into kube-system namespace.
# Run ./certmanager-deploy.sh to deploy with default ca cert.
# Run ./certmanager-deploy.sh -l to deploy with Let's Encrypt Issuer
# Run ./certmanager-deploy.sh -d to delete cert-manager deployment
#
# To be used if namespace gets stuck in 'terminating state'
#kubectl delete apiservice v1beta1.webhook.cert-manager.io
set -oe pipefail

VERSION="v1.10.0"
ISSUER="ca"
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
CM_DIR="${CURRENT_DIR}/../cluster/addons/certmanager"
DELETE=false


# Print usage message to screen
usage() {
  exit_code=$1
  err=$2
  prog=$(basename $0)
  cat <<EOF
Usage:
$prog [OPTIONS] -i <instance_id>[,intance_id,...] -t <instance_type>

Resize one or more EC2 instances.

OPTIONS:
-h|--help             : display usage and exit
-V|--Version          : version of helm chart to install (vX.Y.Z)
-d|--delete           : delete cert-manager and associated resources
-l|--lets-encrypt     : use Let's Encrypt as issuer

Requirements:
* kubectl installed
* helm 3.0+ installed

Examples:
Install with self-signed CA:
$prog

Install with Let's Encrypt CA:
$prog -l

Install with different version:
$prog -V "v1.11.0"

Delete install (using self-signed CA):
$prog -d

Delete install (using Let's Encrypt CA):
$prog -d -l

EOF

  if [ ! -z "$err" ] ; then
  echo "ERROR: $err"
  echo
  fi

  exit $exit_code
}

# Deploy cert-manager
deploy() {

    # Setup helm repo
    helm repo add jetstack https://charts.jetstack.io --force-update
    helm repo update

    # Install helm chart
    helm install \
      cert-manager jetstack/cert-manager \
      --namespace cert-manager \
      --create-namespace \
      --version $VERSION \
      --set installCRDs=true

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
    # Delete our issuers and ca certificate
    kubectl delete -f ${CM_DIR}/files/${ISSUER}-issuer.yaml -n cert-manager
    # Delete cert-manager helm chart
    helm --namespace cert-manager delete cert-manager
    # Delete CRDs
    kubectl delete -f https://github.com/cert-manager/cert-manager/releases/download/$VERSION/cert-manager.crds.yaml

    exit 1
}

while true; do
  case "$1" in
    -h|--help) usage 0 ;;
    -V|--version) VERSION=$2; shift 2 ;;
    -d|--delete) DELETE=true; shift ;;
    -l|--lets-encrypt) ISSUER=le; shift ;;
    *) break ;;
  esac
done

if [ "$DELETE" = true ] ; then
  # Delete helm chart and Resources
  delete
else
  # Deploy cert-mamager manifests
  deploy
fi

# Delete decrypted service account
rm -f ${CM_DIR}/secrets/cert-manager.json || true
