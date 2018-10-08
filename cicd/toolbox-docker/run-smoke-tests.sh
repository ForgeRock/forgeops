#!/usr/bin/env bash
# Work in progress !
# Assumes forgeops source is checked out to /workspace/forgeops
cd /workspace/forgeops

# Namespace is provided in $1
clean_ns() {
    echo "Cleaning up older deployments"
    kubens $1
<<<<<<< c010c60eb1e3a813d278beddac9f76aec7862df1
    ./bin/remove-all.sh 
    kubectl delete secret frconfig
    kubectl delete configmap frconfig
=======
    /forgeops/bin/remove-all.sh -N $1
>>>>>>> Saving work
}

deploy_smoke() {
    echo "deploying the smoke test configuration"
    ./bin/deploy.sh samples/config/smoke-deployment
}

run_tests() {
    echo "Running smoke tests"
    cd /forgeops/cicd/forgeops-tests/
    ./run-smoke-tests.sh
}

get_logs() {
    echo "Getting logs from smoke namespace"
    cd /forgeops/bin
    NAMESPACE=$1 ./get-logs-from-ns.sh
}

sleep_for_30_minutes() {
    echo "Sleeping for 30 minutes for runner to be able to get logs and reports"
    sleep 1800
}

clean_ns smoke
deploy_smoke
run_tests
get_logs smoke
sleep_for_30_minutes
