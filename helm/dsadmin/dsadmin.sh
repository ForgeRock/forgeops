#!/usr/bin/env bash
# Test to see if the pv exists, if it does, launch with the option to skip creation.

ARG=""

kubectl get pv ds-backup && ARG="--set createPVC=false"

set -x
helm delete --purge dsadmin 

helm install --name dsadmin $ARG dsadmin 

