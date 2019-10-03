#!/usr/bin/env bash

set -e pipefail -e errexit -e nounset


mkdir -p /tmp/cluster-0/
# build config
yq -s '.[]' cluster/openshift/installer-config.yaml cluster/openshift/env/example-secrets.yaml > /tmp/cluster-0/install-config.yaml

openshift-installer create cluster -dir /tmp/cluster-0

