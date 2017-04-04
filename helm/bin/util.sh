#!/usr/bin/env bash
# Utility functions - source these in other scripts.

# Location where Helm charts are.
HELMDIR="${DIR}/.."

cd ${HELMDIR}

if [ ! -r ${HELMDIR}/custom.yaml ];
then
    echo "You must provide a ${HELMDIR}/custom.yaml file"
    echo "Copy a custom template from templates/ to custom.yaml, and edit for your environment"
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
