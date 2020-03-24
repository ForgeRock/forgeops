#!/usr/bin/env bash

NAMESPACE=${1:-}
NAMESPACE_CMD=
if [ -z "$NAMESPACE" ]
then 
  NAMESPACE_CMD="" 
else
  echo "Targetting namespace: $NAMESPACE"
  NAMESPACE_CMD="-n $NAMESPACE"
fi
# Delete PVCs.
kubectl $NAMESPACE_CMD delete pvc --all || true

# Clean up secrets
kubectl $NAMESPACE_CMD get secrets | grep am  | kubectl $NAMESPACE_CMD delete secrets $(awk '{ print $1 }')
kubectl $NAMESPACE_CMD get secrets | grep idm | kubectl $NAMESPACE_CMD delete secrets $(awk '{ print $1 }')
kubectl $NAMESPACE_CMD get secrets | grep ds  | kubectl $NAMESPACE_CMD delete secrets $(awk '{ print $1 }')
kubectl $NAMESPACE_CMD delete secret truststore platform-ca || true
