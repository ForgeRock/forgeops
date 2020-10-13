#!/usr/bin/env bash
SECRET_AGENT_VERSION=${SECRET_AGENT_VERSION:-latest}

USAGE="Usage: $0 install|remove"

install() {
    kubectl apply -f https://github.com/ForgeRock/secret-agent/releases/${SECRET_AGENT_VERSION}/download/secret-agent.yaml
}

remove() {
    echo "Warning this is very destructive and will remove all managed secrets"
    echo "Waiting 5 seconds before removing."
    sleep 5
    kubectl delete -f https://github.com/ForgeRock/secret-agent/releases/${SECRET_AGENT_VERSION}/download/secret-agent.yaml

}

cmd=${1}


case "${cmd}" in
    install) install;;
    remove) remove;;
    *) echo "Error: Incorrect usage"
       echo $USAGE
       exit 1;;
esac
