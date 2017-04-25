#!/usr/bin/env bash
# Launch OpenDJ instance using Helm, and wait until it is ready.
# Arg $1 - DJ instance name

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${DIR}/util.sh"

if [ "$#" -lt 1 ]; then
    echo "Usage:   opendj.sh instance-name [helm arguments]"
    exit 1
fi

instance=$1
shift

echo "Configuring instance $instance"

kubectl get pod "${instance}-0" >/dev/null 2>&1

if [ $? == 0 ]; then
    echo "instance ${instance} is already started"
    exit 0
fi

# The OpenDJ instance name is also used as the Helm deployment name
helm install  -f ${CUSTOM_YAML} --set djInstance=${instance} "$@" ${HELM_REPO}/opendj

# DJ is a StatefulSet - so the pod name is well known.
firstPod="${instance}-0"

waitPodReady  ${firstPod}

echo "done"

