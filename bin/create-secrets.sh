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

while [ $i -le  30 ];
do
    if kubectl --namespace "${ns}" apply --filename=../kustomize/base/secrets/secret_agent_config.yaml > /dev/null 2>&1;
    then
        kubectl get --namespace "${ns}" secrets
        echo "deploying secret agent configuration completed"
        exit 0
    fi
    echo "deploying secret agent configuration failed, trying again"
    sleepTime=$(( $i * 2 ))
    sleep $sleepTime

    i=$(( $i + 1 ))
done
exit 1
