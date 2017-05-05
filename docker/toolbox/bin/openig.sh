#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${DIR}/util.sh"

echo helm install -f ${CUSTOM_YAML} ${HELM_REPO}/openig
helm install -f ${CUSTOM_YAML} ${HELM_REPO}/openig
