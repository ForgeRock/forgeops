#!/usr/bin/env bash
# TODO: Remove this script as soon as the helm subchart feature lands

bin/openam.sh

helm install -f helm/global.yaml  helm/cmp-idm-id-postgres

helm install -f helm/global.yaml helm/openig


