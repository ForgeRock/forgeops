#!/bin/bash
################################################################################
# Self Contained ForgeOps OpenAM benchmark test
#
# Please read README.md for setup notes.
#
# This script will do following:
#   - Deploy OpenAM along with DS (CTS, CFGStore, UsrStore)
#   - Ensure configs are in place
#   - Restart OpenAM to take all configuration online
################################################################################

#### Benchmark variables
DOMAIN=.forgeops.com
NAMESPACE=benchmark
AM_URL="openam.$NAMESPACE$DOMAIN"
CLUSTER=s-cluster

#### Setup methods
set_kubectl_context() {
    CURRENT_NAMESPACE=$(kubectl config view | grep namespace:)
    if [[ "$CURRENT_NAMESPACE" != *"$NAMESPACE"* ]]; then
        echo "Setting namespace to $NAMESPACE"
        kubectl config set-context $(kubectl config current-context) \
          --namespace=$NAMESPACE
    fi
}

isalive_check() {
    echo "Running OpenAM alive.jsp check"
    STATUS_CODE=$(curl -LI  http://$AM_URL/openam/isAlive.jsp \
        -o /dev/null -w '%{http_code}\n' -s)
    until [ "$STATUS_CODE" = "200" ]; do
        echo "AM is not alive, waiting 5 seconds before retry..."
        sleep 5
        STATUS_CODE=$(curl -LI  http://$AM_URL/openam/isAlive.jsp \
          -o /dev/null -w '%{http_code}\n' -s)
    done
    echo "OpenAM is alive"
}

checkout_forgeops() {
    rm -rf forgeops/
    echo "Checking out forgeops";
    git clone ssh://git@stash.forgerock.org:7999/cloud/forgeops.git
    echo "Forgeops checked out"
}


#### Deploy methods
deploy() {
    # Update openam chart dependencies
    helm dep up forgeops/helm/openam

    # Create fast storage
    kubectl create -f fast-storage.yaml

    # Deploy amster & openam
    helm install --name openam-$NAMESPACE -f yamls/$CLUSTER/openam.yaml \
        --namespace=$NAMESPACE forgeops/helm/openam
    helm install --name amster-$NAMESPACE -f yamls/$CLUSTER/amster.yaml \
        --namespace=$NAMESPACE forgeops/helm/amster

    # Deploy user/config/cts stores
    helm install --name configstore-$NAMESPACE -f yamls/$CLUSTER/configstore.yaml \
        --namespace=$NAMESPACE forgeops/helm/opendj
    helm install --name userstore-$NAMESPACE -f yamls/$CLUSTER/userstore.yaml \
        --namespace=$NAMESPACE forgeops/helm/opendj
    helm install --name ctsstore-$NAMESPACE -f yamls/$CLUSTER/ctsstore.yaml \
        --namespace=$NAMESPACE forgeops/helm/opendj

}

livecheck_stage1() {
    # This livecheck waits for OpenAM config to be imported.
    # We are looking to amster pod logs periodically.
    echo "Livecheck stage1 - waiting for config to be imported to OpenAM";
    sleep 10
    AMSTER_POD_NAME=$(kubectl get pods --selector=app=amster-$NAMESPACE-amster \
        -o jsonpath='{.items[*].metadata.name}')
    FINISHED_STRING="Configuration script finished"

    while true; do
    OUTPUT=$(kubectl logs $AMSTER_POD_NAME amster)
        if [[ $OUTPUT = *$FINISHED_STRING* ]]; then
            echo "OpenAM configuration import is finished"
            break
        fi
        echo "Configuration not finished yet. Waiting for 10 seconds...."
        sleep 10
    done
}

restart_openam() {
    # We need to restart OpenAM to take CTS settings online
    OPENAM_POD_NAME=$(kubectl get pods --selector=app=openam \
        -o jsonpath='{.items[*].metadata.name}')
    kubectl delete pod $OPENAM_POD_NAME --namespace=$NAMESPACE
    sleep 10
    isalive_check
    echo "Deployment is now prepared for benchmarking"
    echo "Run: 'helm install ../forgeops-benchmark-chart' to run benchmark"
}

#### Main method
set_kubectl_context
checkout_forgeops
deploy
livecheck_stage1
restart_openam
