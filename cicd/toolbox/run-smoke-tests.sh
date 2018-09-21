#!/usr/bin/env bash



# Namespace is provided in $1
clean_ns() {
    echo "Cleaning up older deployments"
    kubens $1
    /forgeops/bin/remove-all.sh 
}

deploy_smoke() {
    echo "deploying the smoke test configuration"
    cd /forgeops
    bin/deploy.sh samples/config/smoke-deployment
}


clean_ns smoke
deploy_smoke

# Todo: Run python tests...
# Do we want the smoke tests to be a separate chart ?
