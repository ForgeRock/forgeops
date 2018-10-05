#!/usr/bin/env bash
# Work in progress !
# Assumes forgeops source is checked out to /workspace/forgeops
cd /workspace/forgeops

# Namespace is provided in $1
clean_ns() {
    echo "Cleaning up older deployments"
    kubens $1
    ./bin/remove-all.sh 
    kubectl delete secret frconfig
    kubectl delete configmap frconfig
}

deploy_smoke() {
    echo "deploying the smoke test configuration"
    ./bin/deploy.sh samples/config/smoke-deployment
}


clean_ns smoke
deploy_smoke

# Todo: Run python tests...
# Do we want the smoke tests to be a separate chart ?
