#!/usr/bin/env bash

# Script to deploy Cert-Manager into cert-manager namespace.
# Run ./deploy-cert-manager.sh .
#
type pulumi > /dev/null
if [ $# -ne 1 ]; then
    echo "Need the path of the pulumi project to target"
    echo "ea. \$BINPATH/.toggle-le-certs.sh ." 
    exit 1
fi

#expand possible relative path
projectFolder=$(cd "$(dirname '$1')" &>/dev/null && printf "%s/%s" "$PWD" "${1##*/}")
printf "\n"
echo "Targetting Pulumi project in: ${projectFolder}"
sleep 5

cd "$(dirname "$0")"
currentState=$(pulumi config get -C "${projectFolder}" certmanager:useselfsignedcert)


# Decrypt encoded service account that has rights to control our dns for the dns01 challenge.

# if we're using self signed certs, make necessary changes to enable letsencrypt provider
if [[ $currentState == "true" ]]; then
        # disable self-signed cert
        pulumi config set -C "${projectFolder}" certmanager:useselfsignedcert false
        # Store the service account as a pulumi secret in the current stack file
        ./decrypt.sh ../secrets/cert-manager.json | pulumi config set --secret  -C "${projectFolder}" certmanager:clouddns  
        echo "Let's encrypt provider enabled"

# if we're using letsencrypt provider, switch back to self signed cert
else
        #enable self-signed cert
        pulumi config set -C "${projectFolder}" certmanager:useselfsignedcert true
        #remove clouddns service account from pulumi
        pulumi config rm -C "${projectFolder}" certmanager:clouddns
        echo "Let's encrypt provider disabled.  Using self-signed certs"
fi



