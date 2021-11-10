#!/usr/bin/env bash
#pipeline-ready
cd "$(dirname "$0")"

SCRIPT_NAME="$(basename "$0")"

usage () {
read -r -d '' help <<-EOF

Create ForgeOps Secrets

This script deploys the SecretAgentConfiguration in a manner that's robust
against busy clusters.

Usage:  ${SCRIPT_NAME} NAMESPACE

EOF
    printf "%-10s \n" "$help"
}

# arg check
if [[ "$#" -ne 1 ]]; then
    echo "Missing required argument"
    usage
    exit 1
fi

ns=$1
i=0

kustomize build ../kustomize/base/secrets | kubectl --namespace "${ns}" apply -f -

sleep 20