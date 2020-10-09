#!/usr/bin/env bash

## This script deploys the Cloud Deployment Quickstart (CDQ). 
set -e 
set -o pipefail

FORGEOPS_REPO="ForgeRock/forgeops"
FORGEOPS_VERSION="latest"
FORGEOPS_NAMESPACE="default"
SECRETAGENT_REPO="ForgeRock/secret-agent"
SECRETAGENT_VERSION="latest"

usage() {
cat <<EOF
ForgeOps Quickstart

A wrapper script that deploys Forgeops Cloud Deployment Quickstart (CDQ) in your target cluster.

Usage:  quickstart.sh [OPTIONS]

Options:
-n      Target namespace for the forgeops deployment. (default: "&{FORGEOPS_NAMESPACE}")
-f      Forgeops version to deploy. (default: "${FORGEOPS_VERSION}")
-s      secret-agent version to deploy. (default: "${SECRETAGENT_VERSION}")
-u      Removes Forgeops CDQ from your cluster
-h      Prints this message

Examples:
    # deploy using default values
    ${0}
    # deploy to "cdqtest" namespace
    ${0} -n cdqtest
    # uninstall the CDQ from "cdqtest" namespace
    ${0} -n cdqtest -u

EOF

}

## Check and install dependencies
installdependencies () {
    printf "Checking secret-agent operator and related CRDs: "
    if ! $(kubectl get crd secretagentconfigurations.secret-agent.secrets.forgerock.io &> /dev/null); then
        printf "secret-agent not found. Installing secret-agent version: '${SECRETAGENT_VERSION}'\n"
        if [ "$SECRETAGENT_VERSION" == "latest" ]; then
            kubectl apply -f "https://github.com/${SECRETAGENT_REPO}/releases/latest/download/secret-agent.yaml"
        else
            kubectl apply -f "https://github.com/${SECRETAGENT_REPO}/releases/download/${SECRETAGENT_VERSION}/secret-agent.yaml"
        fi
        echo "Waiting for secret agent operator..."
        sleep 5
        kubectl wait --for=condition=Established crd secretagentconfigurations.secret-agent.secrets.forgerock.io --timeout=30s
        kubectl -n secret-agent-system wait --for=condition=available deployment  --all --timeout=60s 
        kubectl -n secret-agent-system wait --for=condition=ready pod --all --timeout=60s
    else
        printf "secret-agent CRD found in cluster.\n"
    fi
}

## Deploy the CDQ manifest
deploycdq () {
    echo "Installing Forgeops ${FORGEOPS_REPO}:${FORGEOPS_VERSION}"
    echo "Targeting namespace: ${FORGEOPS_NAMESPACE}"
    echo ""
    if [ "$FORGEOPS_VERSION" == "latest" ]; then
        # kubectl apply -f "https://github.com/${FORGEOPS_REPO}/releases/latest/download/quickstart.yaml"
        curl -sL "https://github.com/${FORGEOPS_REPO}/releases/latest/download/quickstart.yaml" 2>&1 | \
        sed  "s/namespace: default/namespace: ${FORGEOPS_NAMESPACE}/g" | kubectl apply -f -
    else
        # kubectl apply -f "https://github.com/${FORGEOPS_REPO}/releases/download/${FORGEOPS_VERSION}/quickstart.yaml"
        curl -sL "https://github.com/${FORGEOPS_REPO}/releases/download/${FORGEOPS_VERSION}/quickstart.yaml" 2>&1 | \
        sed  "s/namespace: default/namespace: ${FORGEOPS_NAMESPACE}/g" | kubectl apply -f -
    fi
}

## Wait for secrets to be generated
waitforsecrets () {
    echo ""
    printf "waiting for secret: am-env-secrets ."; until kubectl -n ${FORGEOPS_NAMESPACE} get secret am-env-secrets &> /dev/null ; do sleep 1; printf "."; done ; echo "done"
    printf "waiting for secret: idm-env-secrets ."; until kubectl -n ${FORGEOPS_NAMESPACE} get secret idm-env-secrets &> /dev/null ; do sleep 1; printf "."; done; echo "done"
    printf "waiting for secret: ds-passwords ."; until kubectl -n ${FORGEOPS_NAMESPACE} get secret ds-passwords &> /dev/null ; do sleep 1; printf "."; done; echo "done"
    printf "waiting for secret: ds-env-secrets ."; until kubectl -n ${FORGEOPS_NAMESPACE} get secret ds-env-secrets &> /dev/null ; do sleep 1; printf "."; done; echo "done"
    echo ""
}

## Uninstall the CDQ manifest
uninstallcdq () {
    echo "Uninstalling the CDQ"
    echo "Targeting namespace: ${FORGEOPS_NAMESPACE}"
    echo ""
    if [ "$FORGEOPS_VERSION" == "latest" ]; then
        # kubectl apply -f "https://github.com/${FORGEOPS_REPO}/releases/latest/download/quickstart.yaml"
        curl -sL "https://github.com/${FORGEOPS_REPO}/releases/latest/download/quickstart.yaml" 2>&1 | \
        sed  "s/namespace: default/namespace: ${FORGEOPS_NAMESPACE}/g" | kubectl delete -f -
    else
        # kubectl apply -f "https://github.com/${FORGEOPS_REPO}/releases/download/${FORGEOPS_VERSION}/quickstart.yaml"
        curl -sL "https://github.com/${FORGEOPS_REPO}/releases/download/${FORGEOPS_VERSION}/quickstart.yaml" 2>&1 | \
        sed  "s/namespace: default/namespace: ${FORGEOPS_NAMESPACE}/g" | kubectl delete -f -
    fi
    kubectl -n ${FORGEOPS_NAMESPACE} delete pvc --all || true
}

getsec () {
    kubectl -n ${FORGEOPS_NAMESPACE} get secret $1 -o jsonpath="{.data.$2}" | base64 --decode
}

## Print secrets
printsecrets () {
    echo "Relevant passwords:"
    echo "$(getsec am-env-secrets AM_PASSWORDS_AMADMIN_CLEAR) (amadmin user)"
    echo "$(getsec idm-env-secrets OPENIDM_ADMIN_PASSWORD) (openidm-admin user)"
    echo "$(getsec ds-passwords dirmanager\\.pw) (uid=admin user)"
    echo "$(getsec ds-env-secrets AM_STORES_APPLICATION_PASSWORD) (App str svc acct (uid=am-config,ou=admins,ou=am-config))"
    echo "$(getsec ds-env-secrets AM_STORES_CTS_PASSWORD) (CTS svc acct (uid=openam_cts,ou=admins,ou=famrecords,ou=openam-session,ou=tokens))"
    echo "$(getsec ds-env-secrets AM_STORES_USER_PASSWORD) (ID repo svc acct (uid=am-identity-bind-account,ou=admins,ou=identities))"

}
## OSX does not come with `timeout` pre-installed. 
timeout() { perl -e 'alarm shift; exec @ARGV' "$@"; }

UNINSTALL_CDQ=false
# list of arguments expected in the input
optstring=":hun:f:s:"
while getopts ${optstring} arg; do
  case ${arg} in
    h) echo "Usage:"; usage; exit 0;;
    n) FORGEOPS_NAMESPACE=${OPTARG};;
    f) FORGEOPS_VERSION=${OPTARG};;
    s) SECRETAGENT_VERSION=${OPTARG};;
    u) UNINSTALL_CDQ=true;;
    :)
      echo "$0: Must supply an argument to -$OPTARG." >&2
      usage
      exit 1
      ;;
    ?)
      echo "Invalid option: -${OPTARG}."
      usage
      exit 2
      ;;
  esac
done

echo ""
if [ ${UNINSTALL_CDQ} = true ]; then
    uninstallcdq
    exit 0
fi
echo "Installing the CDQ"
installdependencies
sleep 10
deploycdq
## Call waitforsecrets with a 2 minute timeout
timeout 120s cat <( waitforsecrets )
printsecrets
