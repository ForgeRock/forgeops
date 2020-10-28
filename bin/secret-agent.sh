#!/usr/bin/env bash
SECRET_AGENT_VERSION=${SECRET_AGENT_VERSION:-latest}

USAGE="Usage: $0 install|remove"

install() {
    printf "Checking secret-agent operator and related CRDs: "
    if ! $(kubectl get crd secretagentconfigurations.secret-agent.secrets.forgerock.io &> /dev/null); then
        printf "secret-agent not found. Installing secret-agent version: '${SECRET_AGENT_VERSION}'\n"
        if [ "$SECRET_AGENT_VERSION" == "latest" ]; then
            kubectl apply -f "https://github.com/ForgeRock/secret-agent/releases/latest/download/secret-agent.yaml"
        else
            kubectl apply -f "https://github.com/ForgeRock/secret-agent/releases/download/${SECRET_AGENT_VERSION}/secret-agent.yaml"
        fi
        echo "Waiting for secret agent operator..."
        sleep 5
        kubectl wait --for=condition=Established crd secretagentconfigurations.secret-agent.secrets.forgerock.io --timeout=30s
        kubectl -n secret-agent-system wait --for=condition=available deployment  --all --timeout=60s 
        kubectl -n secret-agent-system wait --for=condition=ready pod --all --timeout=60s
    else
        printf "secret-agent CRD found in cluster. Skipping secret-agent installation.\n"
    fi
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
