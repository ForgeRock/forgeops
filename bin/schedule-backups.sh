#!/usr/bin/env bash
# Simple script to schedule DS backups


kcontext=$(kubectl config current-context)
NS=$(kubectl config view -o jsonpath="{.contexts[?(@.name==\"$kcontext\")].context.namespace}")
if [ $# = '1' ]; then
    NAMESPACE=$1
else
    NAMESPACE=$NS
fi

if [[ -z "$NAMESPACE" ]] ; then
    echo 'Please provide the target namespace. e.a. schedule-backups.sh namespace-name'
    exit -1
fi

pods=( $(kubectl get pods -n $NAMESPACE | grep ds | echo $(awk '{ print $1 }')) )
for pod in "${pods[@]}"
do
  echo ""
  echo "scheduling backup for pod: $pod"
  kubectl -n $NAMESPACE exec -ti $pod ./scripts/schedule-backup.sh
done

