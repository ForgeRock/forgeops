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

# We name the Helm deployment the same as the OpenDJ instance name.
# This makes it easier to remove the deployment at a known name.
helm install --name ${instance}  -f custom.yaml --set djInstance=${instance}  "$@" opendj


# DJ is a StatefulSet - so the pod name is well known.
firstPod="${instance}-0"

waitPodReady  ${firstPod}

echo "done"

