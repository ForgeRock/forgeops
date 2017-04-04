#!/usr/bin/env bash
# Trigger an export of the openam configuration.

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${DIR}/util.sh"

amster=`findPod app=amster`

echo $amster

if [ -z "${amster}" ]; then
    echo "No amster pod found."
    exit 1
fi

# The amster pod contains an export.sh script to export the contents of OpenAM to the
# mounted /amster volume.

kubectl exec $amster -it ./export.sh
