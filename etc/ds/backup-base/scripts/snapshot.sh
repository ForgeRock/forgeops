#!/usr/bin/env bash
# This script is called by the cron job to manage snapshots, pvcs and the backup job.
# It snapshots the desired disk (default date-ds-idrepo-0) and then creates a cloned PVC from the snapshot.
# The cloned pvc is then used by the customer supplied job to backup the directory server. On job
# completion the script will clean up the Job. This is required to get the job to release the cloned PVC so it can be
# reclaimed.
#
# set -x


DS_VOLUME="${1:-data-ds-idrepo-0}"
DS_CLONE_PVC="${2:-$DS_VOLUME-clone}"

JOB_NAME=ds-backup

# To use the pod name for the snap - instead of a fixed name
SNAP_NAME=$POD_NAME
# SNAP_NAME="snap-$DS_VOLUME"

# Delete snapshots older than this date. You can use 'last day', 'last hour', '-10 min', etc.
purgeTime=$(date -d '-1 hour' -Ins --utc)

#
for snapshot in $(kubectl --namespace $NAMESPACE get volumesnapshot -l app=ds-snapshot-job  -o jsonpath="{.items[*].metadata.name}")
do
  dt=$(kubectl  --namespace $NAMESPACE get volumesnapshot $snapshot -o jsonpath="{.metadata.creationTimestamp"})

  # This does a lexigraphical comparison which works because the string is in UTC format
  if [[ $dt < $purgeTime ]]; then
    echo "Purging $snapshot with age $dt"
    kubectl --namespace $NAMESPACE delete volumesnapshot $snapshot
  else
    echo "Snapshot $snapshot creation time $dt is newer than $purgeTime. Retaining"
  fi

done

# If there is an existing job we need to terminate - we don't want to create multiple overlapping jobs
# This should not happen, but just in case...
kubectl --namespace $NAMESPACE get job $JOB_NAME && {
   echo "Existing job $JOB_NAME is still running. Exiting"
   exit 1
}

echo "Creating snapshot $NAMESPACE/$SNAP_NAME"

kubectl --namespace  $NAMESPACE apply -f  - <<EOF
apiVersion: snapshot.storage.k8s.io/v1beta1
kind: VolumeSnapshot
metadata:
  name: $SNAP_NAME
  labels:
    app: ds-snapshot-job
spec:
  # Your cluster admin needs to create the volume snapshot class
  volumeSnapshotClassName: ds-snapshot-class
  source:
    persistentVolumeClaimName: $DS_VOLUME
EOF


# Wait for snapshot to be ready
while true
do
  echo "Waiting on snapshot $SNAP_NAME to be ready for use"
  sleep 5
  stat=$(kubectl --namespace $NAMESPACE get volumesnapshot $SNAP_NAME -o=jsonpath='{.status.readyToUse}')
  echo $stat
  if [ $stat == 'true' ]; then
    break;
  fi

done

echo "Deleting $DS_CLONE_PVC if it exists"
kubectl --namespace $NAMESPACE delete pvc $DS_CLONE_PVC || echo "pvc not present. This is not a problem"

sleep 5


# Now create the pvc that uses that snapshot

diskSize=$(kubectl get pvc $DS_VOLUME -o jsonpath='{.spec.resources.requests.storage}' )

kubectl --namespace $NAMESPACE apply -f -  <<EOF
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: $DS_CLONE_PVC
  annotations:
    pv.beta.kubernetes.io/gid: "0"
spec:
  storageClassName: standard-rwo
  resources:
    requests:
      storage: $diskSize
  accessModes: [ "ReadWriteOnce" ]
  dataSource:
    name: $SNAP_NAME
    kind: VolumeSnapshot
    apiGroup: snapshot.storage.k8s.io
EOF

# Launch the user supplied DS backup job

echo "Starting the DS backup job"
# Sed is used to set the name of the PVC to be cloned.
 sed </opt/scripts/job.yaml -e s/DS_DATA_CLONE_DISK/$DS_CLONE_PVC/ | kubectl --namespace $NAMESPACE apply -f -

# Loop and watch for the job to finish
# If the loop falls through something has probably gone wrong..
i=0
while [ $i -ne 30 ]
do
  echo "Waiting on job $JOB_NAME"
  kubectl --namespace $NAMESPACE wait --for=condition=complete --timeout=30s job $JOB_NAME
  if [ $? == 0 ] ; then
    echo "Job finished. Job logs"
    kubectl --namespace $NAMESPACE  --all-containers=true logs job/$JOB_NAME
    echo "Cleaning up job"
    kubectl --namespace $NAMESPACE delete job $JOB_NAME
    exit 0
  fi
  i=$(($i+1))
done

echo "Job $JOB_NAME did not complete in time. Exiting"
exit 1

