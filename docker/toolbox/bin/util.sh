#!/usr/bin/env bash
# Utility functions - source these in other scripts.

PROJECT_HOME="${DIR}/.."

# Location where Helm charts are.
HELMDIR="${DIR}/../helm"

# Set to helm to use helm charts in this project, or to a remote repo name if your charts are on a remote server
HELM_REPO=${HELM_REPO:-"helm"}


cd ${PROJECT_HOME}

CUSTOM_YAML=${CUSTOM_YAML:-./custom.yaml}

#echo "PROJECT_HOME is ${PROJECT_HOME}"
echo "CUSTOM_YAML is ${CUSTOM_YAML}"

if [ ! -r ${CUSTOM_YAML} ];
then
    echo "You must provide a ${CUSTOM_YAML} file."
    echo "Copy a custom template from templates/ or set the environment variable CUSTOM_YAML the path to your custom.yaml."
    exit 1
fi

# Wait for a pod to be ready. This only works on the first container of a pod!
waitPodReady() {
    ready="false"
    echo "Waiting for pod $1 to be ready"

    while [ ! "${ready}" = "true" ] ; do
        sleep 10
         ready=`kubectl get pod $1 -o jsonpath={.status.containerStatuses[0].ready}`
        printf "."
    done
}

# Find a pod with the given label descriptor in $1.
findPod() {
    kubectl get pod -l $1 --no-headers | awk '{print $1;}'
}

NS=`kubectl config view | grep namespace | awk  '{print $2}'`
DEFAULT_NAMESPACE=${NS:-default}
export DEFAULT_NAMESPACE
