#!/usr/bin/env bash
# Script to restore a volume snapshot to a DS statefulset.
#set -oe pipefail

# Grab our starting dir
start_dir=$(pwd)
# Figure out the dir we live in
SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
# Bring in our standard functions
source $SCRIPT_DIR/stdlib.sh
cd $start_dir

usage() {
    exit_code=$1
    err=$2
    prog=$(basename $0)
    cat <<EOM
Usage: $prog [OPTIONS] ACTION RESTORE_TARGET

Restore a DS StatefulSet from a VolumeSnapshot. When doing a full restore, the
StatefulSet will be scaled down to 0 pods, the existing PVCs will be recreated
with the snapshot as the data source. This operation requires downtime.

The selective restore creates a new PVC, StatefulSet, and Service that creates a
single new DS pod. This allows you to selectively export and import data as
needed. After restoring all needed data, the clean action will clean up the
temporary resources. You need to use --dir to specify the restore dir when using
clean.

NOTES:
  * Valid restore actions: ${VALID_ACTIONS[@]}
  * Valid restore targets: ${VALID_TARGET[@]}
  * Only one action and target allowed per run
  * If a namespace isn't supplied, kubectl will rely on context and environment

  OPTIONS:
    -h|--help                    : display usage and exit
    --debug                      : enable debugging output
    --dryrun                     : do a dry run
    -v|--verbose                 : be verbose
    -d|--dir /path/to/restore/   : path to dir to use for restore artifacts
    -n|--namespace NAMESPACE     : namespace to work in
    -s|--snapshot SNAPSHOT_NAME  : name of the snapshot to restore from
                                   (default: latest snapshot)

Requirements:
  * kubectl
  * jq
  * yq (mikefarrah) 4.x+

Examples:
  Full restore of latest snapshot on idrepo:
  $prog -n my-namespace full idrepo

  Full restore of specific snapshot on cts:
  $prog -s ds-idrepo-snapshot-20231003-0000 full cts

  Use a specific dir for restore artifacts:
  $prod -d $HOME/ds-restore -s ds-idrepo-snapshot-20231003-0000 full idrepo

  Selective restore of specific snapshot for idrepo:
  $prog -s ds-idrepo-snapshot-20231003-0000 selective idrepo

  Clean up k8s resources from selective restore:
  $prog -d /tmp/snapshot-restore-idrepo.20231003T21:40:53Z clean

EOM

  if [ ! -z "$err" ] ; then
    echo "ERROR: $err"
    echo
  fi

  exit $exit_code
}

# Use runOrPrint to execute kubectl, and apply the namespace
kube() {
  message "Starting kube()" "debug"

  runOrPrint "$K_CMD $* $NAMESPACE_OPT"

  message "Finishing kube()" "debug"
}

# Strip k8s metadata out of a yaml file
stripMetadata() {
  message "Starting stripMetadata()" "debug"

  local file=$1
  local newfile="${file}.new"
  local jq_filter=$(cat <<-END
    del(
      .metadata.annotations."autoscaling.alpha.kubernetes.io/conditions",
      .metadata.annotations."autoscaling.alpha.kubernetes.io/current-metrics",
      .metadata.annotations."control-plane.alpha.kubernetes.io/leader",
      .metadata.annotations."deployment.kubernetes.io/revision",
      .metadata.annotations."kubectl.kubernetes.io/last-applied-configuration",
      .metadata.annotations."kubernetes.io/service-account.uid",
      .metadata.annotations."pv.kubernetes.io/bind-completed",
      .metadata.annotations."pv.kubernetes.io/bound-by-controller",
      .metadata.finalizers,
      .metadata.managedFields,
      .metadata.creationTimestamp,
      .metadata.generation,
      .metadata.resourceVersion,
      .metadata.selfLink,
      .metadata.uid,
      .spec.clusterIP,
      .spec.clusterIPs,
      .spec.progressDeadlineSeconds,
      .spec.revisionHistoryLimit,
      .spec.template.metadata.annotations."kubectl.kubernetes.io/restartedAt",
      .spec.template.metadata.creationTimestamp,
      .spec.volumeName,
      .spec.volumeMode,
      .status
    )
END)

  cat $file | \
  jq --exit-status --compact-output --monochrome-output --raw-output --sort-keys 2>/dev/null "$jq_filter" | \
  yq eval --prettyPrint --no-colors --exit-status - > $newfile

  mv $newfile $file

  message "Finishing stripMetadata()" "debug"
}

# Merge two yaml files together
mergeYaml() {
  message "Starting mergeYaml()" "debug"

  local file=$1
  local add_file=$2
  local newfile="$$_new.yaml"

  yq eval-all '. as $item ireduce ({}; . * $item)' $file $add_file > $newfile
  mv $newfile $file

  message "Finishing mergeYaml()" "debug"
}

# Get the currently running service definition
getSvc() {
  message "Starting getSvc()" "debug"

  $K_GET svc ds-$TARGET -o json > $SVC_PATH
  stripMetadata $SVC_PATH

  message "Finishing getSvc()" "debug"
}

# Prep the service when doing a selective restore
prepSvc() {
  message "Starting prepSvc()" "debug"

  if [ "$ACTION" == "selective" ] ; then
    sed -i .bak -e "s/ds-$TARGET/ds-$TARGET-restore/" $SVC_PATH
  fi

  message "Finishing prepSvc()" "debug"
}

# Apply the SVC
applySvc() {
  message "Starting applySvc()" "debug"

  kube apply -f $SVC_PATH

  message "Finishing applySvc()" "debug"
}

# Get the currently running STS definition
getSts() {
  message "Starting getSts()" "debug"

  $K_GET sts ds-$TARGET -o json > $STS_PATH
  stripMetadata $STS_PATH

  message "Finishing getSts()" "debug"
}

# Prep the restore STS based on the restore type
prepSts() {
  message "Starting prepSts()" "debug"

  if [ "$ACTION" == "full" ] ; then
    sed -e 's/replicas: [0-9]*$/replicas: 0/' $STS_PATH > $STS_RESTORE_PATH
  elif [ "$ACTION" == "selective" ] ; then
    sed -e 's/replicas: *$/replicas: 1/' $STS_PATH > $STS_RESTORE_PATH
    sed -i .bak -e "s/ds-$TARGET/ds-$TARGET-restore/g" $STS_RESTORE_PATH

    createPvcAdd
    yq eval-all \
      'select(fileIndex==0).spec.volumeClaimTemplates[0] = select(fileIndex==1) | select(fileIndex==0)' \
      $STS_RESTORE_PATH $PVC_ADD_FILE > $STS_RESTORE_PATH.new
    mv $STS_RESTORE_PATH.new $STS_RESTORE_PATH
  fi

  message "Finishing prepSts()" "debug"
}

# Apply the STS
applySts() {
  message "Starting applySts()" "debug"

  kube apply -f $STS_RESTORE_PATH

  message "Finishing applySts()" "debug"
}

# Restore the STS when doing a full restore
restoreSts() {
  message "Starting restoreSts()" "debug"

  kube apply -f $STS_PATH

  message "Finishing restoreSts()" "debug"
}

# Create a file to hold the snapshot to source from. Merged with another file
createPvcAdd() {
  message "Starting createPvcAdd()" "debug"

  local temp_add_file="$RESTORE_DIR/pvc_snip.yaml"
  cat > $temp_add_file << EOM
spec:
  dataSource:
    name: $SNAPSHOT_NAME
    kind: VolumeSnapshot
    apiGroup: snapshot.storage.k8s.io
EOM

  if [ "$ACTION" == "full" ] ; then
    mv $temp_add_file $PVC_ADD_FILE
  elif [ "$ACTION" == "selective" ] ; then
    local vct_file="$RESTORE_DIR/vct.yaml"
    yq -r '.spec.volumeClaimTemplates[0]' $STS_RESTORE_PATH > $vct_file
    mergeYaml $vct_file $temp_add_file
    mv $vct_file $PVC_ADD_FILE
  fi

  message "Finishing createPvcAdd()" "debug"
}

# Get our list of PVCs to work with when doing a full restore
getPvcs() {
  message "Starting getPvcs()" "debug"

  PVCS=$($K_GET pvc -l "app.kubernetes.io/instance=ds-${TARGET}" --no-headers=true | awk '{ print $1 }')
  for pvc in $PVCS ; do
    local pvc_path="${RESTORE_DIR}/${pvc}.yaml"
    $K_GET pvc $pvc -o json > $pvc_path
    stripMetadata $pvc_path
  done

  message "Finishing getPvcs()" "debug"
}

# Prep our PVCs to be created from the snapshot
prepPvcs() {
  message "Starting prepPvcs()" "debug"

  createPvcAdd
  for pvc in $PVCS ; do
    local file="$RESTORE_DIR/${pvc}.yaml"
    mergeYaml $file $PVC_ADD_FILE
  done

  message "Finishing prepPvcs()" "debug"
}

# Delete existing PVCs
deletePvcs() {
  message "Starting deletePvcs()" "debug"

  for pvc in $PVCS ; do
    kube delete pvc $pvc
  done

  message "finishing deletePvcs()" "debug"
}

# Create new PVCs
createPvcs() {
  message "Starting createPvcs()" "debug"

  for pvc in $PVCS ; do
    kube apply -f $RESTORE_DIR/${pvc}.yaml
  done

  message "Finishing createPvcs()" "debug"
}

# Defaults
DEBUG=false
DRYRUN=false
VERBOSE=false

ACTION=
NAMESPACE=
RESTORE_DIR=
SNAPSHOT_NAME=
TARGET=

VALID_ACTIONS=("full" "selective" "clean")
VALID_TARGET=("idrepo" "cts")

while true; do
  case "$1" in
    -h|--help) usage 0 ;;
    --debug) DEBUG=true; shift ;;
    --dryrun) DRYRUN=true; shift ;;
    -v|--verbose) VERBOSE=true; shift ;;
    -d|--dir) RESTORE_DIR=$2; shift 2 ;;
    -n|--namespace) NAMESPACE=$2; shift 2 ;;
    -s|--snapshot) SNAPSHOT_NAME=$2; shift 2 ;;
    "") break ;;
    *) if [ -z $ACTION ] ; then
         ACTION=$1
         shift
       elif [ -z $TARGET ] ; then
         TARGET=$1
         shift
       else
         usage 1 "Unknown flag: $1"
       fi
       ;;
  esac
done

message "DEBUG=$DEBUG" "debug"
message "DRYRUN=$DRYRUN" "debug"
message "VERBOSE=$VERBOSE" "debug"

message "ACTION=$ACTION" "debug"
message "NAMESPACE=$NAMESPACE" "debug"
message "SNAPSHOT_NAME=$SNAPSHOT_NAME" "debug"
message "TARGET=$TARGET" "debug"

if [ "$ACTION" == "clean" ] && [ -z $RESTORE_DIR ] ; then
  usage 1 "You must use -d/--dir with clean"
fi

# Namespace string
if [ -z $NAMESPACE ] ; then
  NAMESPACE_OPT=""
else
  NAMESPACE_OPT="-n $NAMESPACE"
fi

# kubectl commands
K_CMD="$(type -P kubectl)"
K_GET="$K_CMD get $NAMESPACE_OPT"

if containsElement $ACTION ${VALID_ACTIONS[@]} ; then
  message "Restore type is valid: $ACTION" "debug"
else
  usage 1 "Invalid restore type: $ACTION"
fi

if [ -n $TARGET ] ; then
  if containsElement $TARGET ${VALID_TARGET[@]} ; then
    message "Restore target is valid: $TARGET" "debug"
  else
    usage 1 "Invalid restore target: $TARGET"
  fi
fi

JOB_LABEL="ds-${TARGET}-snapshot-job"
message "JOB_LABEL=$JOB_LABEL" "debug"

# Use latest snapshot if none given
if [ -z "$SNAPSHOT_NAME" ] ; then
  message "No snapshot name given to use for restore. Using latest." "debug"
  SNAPSHOT_NAME=$($K_GET volumesnapshot -l "app=$JOB_LABEL" | tail -1 | awk '{ print $1 }')
fi
message "SNAPSHOT_NAME=$SNAPSHOT_NAME" "debug"

# Setup directory to hold files needed to do the restore
if [ -z "$RESTORE_DIR" ] && [ "$ACTION" == "clean" ]; then
  usage 1 "Must supply -d|--dir when doing a clean"
elif [ -z "$RESTORE_DIR" ] ; then
  TIMESTAMP=$(date -u "+%Y%m%dT%TZ")
  RESTORE_DIR=/tmp/snapshot-restore-${TARGET}.$TIMESTAMP
fi
message "RESTORE_DIR=$RESTORE_DIR" "debug"

if [ ! -d "$RESTORE_DIR" ] ; then
  mkdir -p $RESTORE_DIR
fi

PVC_ADD_FILE="$RESTORE_DIR/pvc_add.yaml"
STS_FILE="sts.yaml"
STS_PATH="$RESTORE_DIR/$STS_FILE"
STS_RESTORE_FILE="sts-restore.yaml"
STS_RESTORE_PATH="$RESTORE_DIR/$STS_RESTORE_FILE"
SVC_FILE="svc.yaml"
SVC_PATH="$RESTORE_DIR/$SVC_FILE"

case $ACTION in
  full)
    message "Requested restore type: full" "debug"
    getSts
    prepSts
    applySts
    getPvcs
    prepPvcs
    deletePvcs
    createPvcs
    restoreSts
    ;;

  selective)
    message "Requested restore type: selective" "debug"
    getSts
    prepSts
    applySts
    getSvc
    prepSvc
    applySvc
    ;;

  clean)
    message "Requested restore type: clean" "debug"
    tgt_name="ds-${TARGET}-restore"
    kube delete svc $tgt_name --ignore-not-found=true
    kube delete sts $tgt_name --ignore-not-found=true
    kube delete pvc -l "app.kubernetes.io/instance=$tgt_name" --ignore-not-found=true
    ;;
esac
