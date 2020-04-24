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
#only set $ADMIN_PASSWORD if the secret is available. This information is only used in 7.0.
if [[ $(kubectl -n $NAMESPACE get secret ds-passwords -o jsonpath="{.data.dirmanager\.pw}") ]] &>/dev/null; then
  ADMIN_PASSWORD=$(kubectl -n $NAMESPACE get secret ds-passwords -o jsonpath="{.data.dirmanager\.pw}" | base64 --decode)
fi
for pod in "${pods[@]}"
do
  echo ""
  echo "scheduling backup for pod: $pod"
  kubectl -n $NAMESPACE exec $pod -- bash -c "ADMIN_PASSWORD=$ADMIN_PASSWORD ./scripts/schedule-backup.sh"
done

