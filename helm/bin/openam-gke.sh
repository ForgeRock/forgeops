#!/usr/bin/env bash
# Example of a larger configuration.

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${DIR}/util.sh"

cp ${HELMDIR}/templates/custom-gke.yaml ${HELMDIR}/custom.yaml

exec ${HELMDIR}/bin/openam.sh

