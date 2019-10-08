#!/bin/bash

###############################################################################
# Copyright (c) 2018 Red Hat Inc
#
# See the NOTICE file(s) distributed with this work for additional
# information regarding copyright ownership.
#
# This program and the accompanying materials are made available under the
# terms of the Eclipse Public License 2.0 which is available at
# http://www.eclipse.org/legal/epl-2.0
#
# SPDX-License-Identifier: EPL-2.0
#
# Run ./kill-kube-ns.sh <namespace>
#
###############################################################################

set -eo pipefail

die() { echo "$*" 1>&2 ; exit 1; }

need() {
	which "$1" &>/dev/null || die "Binary '$1' is missing but required"
}

# checking pre-reqs

need "jq"
need "curl"
need "kubectl"

PROJECT="$1"
shift

test -n "$PROJECT" || die "Missing arguments: kill-ns <namespace>"

kubectl proxy &>/dev/null &
PROXY_PID=$!
killproxy () {
	kill $PROXY_PID
}
trap killproxy EXIT

sleep 1 # give the proxy a second

kubectl get namespace "$PROJECT" -o json | jq 'del(.spec.finalizers[] | select("kubernetes"))' | curl -s -k -H "Content-Type: application/json" -X PUT -o /dev/null --data-binary @- http://localhost:8001/api/v1/namespaces/$PROJECT/finalize && echo "Killed namespace: $PROJECT"
