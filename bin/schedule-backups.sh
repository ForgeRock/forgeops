#!/usr/bin/env bash
# Simple script to schedule DS backups

pods=( $(kubectl get pods | grep ds | echo $(awk '{ print $1 }')) )
for pod in "${pods[@]}"
do
  echo ""
  echo "scheduling backup for pod: $pod"
  kubectl exec -ti $pod ./scripts/schedule-backup.sh
done

