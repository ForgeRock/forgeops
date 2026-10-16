#!/bin/sh
# This script is called by the cron job to manage snapshots, pvcs and the backup job.
# It snapshots the desired disk (default date-ds-idrepo-0) and then creates a cloned PVC from the snapshot.
# The cloned pvc is then used by the customer supplied job to backup the directory server. On job
# completion the script will clean up the Job. This is required to get the job to release the cloned PVC so it can be
# reclaimed.
#

DEBUG=${DEBUG:-false}
if [ "$DEBUG" = true ] ; then
  set -x
fi

if [ $# -gt 0 ]; then
  DS_SNAPSHOT_NAME=$1
  DS_VOLUME=$2
  DS_SNAPSHOT_CLASS=$3
fi

[ -z "$DS_SNAPSHOT_NAME" ] && DS_SNAPSHOT_NAME="ds-snapshot"
[ -z "$DS_VOLUME" ] && DS_VOLUME="data-ds-idrepo-0"
[ -z "$DS_SNAPSHOT_CLASS" ] && DS_SNAPSHOT_CLASS="ds-snapshot-class"

# To use the pod name for the snap - instead of a fixed name
SNAP_NAME=$DS_SNAPSHOT_NAME-$(date +%Y%m%d-%H%M --utc)

JOB_NAME="${DS_SNAPSHOT_NAME}-job"

# Delete snapshots older than this date. Set env PURGE_DELAY to a valid date
# range. You can use 'last day', 'last hour', '-10 min', etc. (GNU date
# syntax). Busybox date (the alpine/kubectl cronjob image) understands none
# of those forms, so on busybox the common relative expressions are parsed
# here instead; anything else fails loudly rather than purging everything.
if date -d "last day" +%s >/dev/null 2>&1; then
  purgeTime=$(date -d "$PURGE_DELAY" --utc +%s)
else
  case "$PURGE_DELAY" in
    *"last day"*)   OFFSET=$((24*3600)) ;;
    *"last hour"*)  OFFSET=3600 ;;
    *"last week"*)  OFFSET=$((7*24*3600)) ;;
    [0-9]*" min")   OFFSET=$(( ${PURGE_DELAY%% min*} * 60 )) ;;
    [0-9]*" hour"*) OFFSET=$(( ${PURGE_DELAY%% hour*} * 3600 )) ;;
    [0-9]*" day"*)  OFFSET=$(( ${PURGE_DELAY%% day*} * 86400 )) ;;
    "") echo "PURGE_DELAY is not set; not purging old snapshots" >&2; OFFSET="" ;;
    *) echo "Cannot parse PURGE_DELAY='$PURGE_DELAY' with busybox date; not purging" >&2; OFFSET="" ;;
  esac
  if [ -n "$OFFSET" ]; then
    purgeTime=$(( $(date -u +%s) - OFFSET ))
  fi
fi

#
for snapshot in $(kubectl --namespace $NAMESPACE get volumesnapshot -l app="${JOB_NAME}"  -o jsonpath="{.items[*].metadata.name}")
do
  # kubectl's creationTimestamp is ISO-8601 with a trailing Z, which busybox
  # date rejects; GNU date accepts both. Normalize to what the running
  # implementation parses.
  CREATION_TS=$(kubectl --namespace $NAMESPACE get volumesnapshot $snapshot -o jsonpath="{.metadata.creationTimestamp}")
  if date -d "last day" +%s >/dev/null 2>&1; then
    dt=$(date -d "$CREATION_TS" +%s)
  else
    dt=$(date -u -D "%Y-%m-%dT%H:%M:%S" -d "${CREATION_TS%Z}" +%s)
  fi

  # This does a lexigraphical comparison which works because the string is in UTC format
  if [ -z "$purgeTime" ]; then
    echo "No purge cutoff; retaining $snapshot"
  elif [ "$dt" -lt "$purgeTime" ]; then
    echo "Purging $snapshot with age $dt"
    kubectl --namespace $NAMESPACE delete volumesnapshot $snapshot
  else
    echo "Snapshot $snapshot creation time $dt is newer than $purgeTime. Retaining"
  fi

done

echo "Creating snapshot $NAMESPACE/$SNAP_NAME"

kubectl --namespace  $NAMESPACE apply -f - <<EOF
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: $SNAP_NAME
  labels:
    app: $JOB_NAME
spec:
  # The volume snapshot class needs to exist in the cluster
  volumeSnapshotClassName: $DS_SNAPSHOT_CLASS
  source:
    persistentVolumeClaimName: $DS_VOLUME
EOF


if [ $? == 0 ] ; then
  echo "Job finished. Job logs"
  kubectl --namespace $NAMESPACE wait -l app="${DS_SNAPSHOT_NAME}-job" --for=condition=Ready pod
  kubectl --namespace $NAMESPACE  --all-containers=true logs -l app="${DS_SNAPSHOT_NAME}-job"
  # The backup job owns the cloned PVC via its volumeMounts; the job must be
  # deleted for the PVC to be released and reclaimed (the header above
  # promises this cleanup).
  kubectl --namespace $NAMESPACE delete job -l app="${DS_SNAPSHOT_NAME}-job"
  exit 0
fi

echo "Job $DS_SNAPSHOT_NAME did not complete successfully. Exiting"
exit 1
