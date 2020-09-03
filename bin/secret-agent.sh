#!/usr/bin/env bash
SECRET_AGENT_VERSION=master

USAGE="Usage: $0 install|remove"

install() {
    kustomize build \
        "github.com/ForgeRock/secret-agent//config/default/?ref=${SECRET_AGENT_VERSION}" | kubectl apply -f -
}

remove() {
    echo "Warning this is very destructive and will remove all managed secrets"
    echo "Waiting 5 seconds before removing."
    sleep 5
    kustomize build \
        "github.com/ForgeRock/secret-agent//config/default" | kubectl delete -f -
}

cmd=${1}


case "${cmd}" in
    install) install;;
    remove) remove;;
    *) echo "Error: Incorrect usage"
       echo $USAGE
       exit 1;;
esac
