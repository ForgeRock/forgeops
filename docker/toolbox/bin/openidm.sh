#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${DIR}/util.sh"

helm install -f ${CUSTOM_YAML} ${HELM_REPO}/postgres-openidm

echo "Starting an OpenDJ user store instance"

${DIR}/opendj.sh userstore

# todo: probe for pod ready instead of sleeping
echo "Waiting for Postgres to start"

pod=`findPod "app=openidm-postgres"`

waitPodReady $pod

# Start OpenIDM.

echo "Starting OpenIDM"

helm install -f ${CUSTOM_YAML} ${HELM_REPO}/openidm

