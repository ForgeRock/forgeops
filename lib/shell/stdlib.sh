runOrPrint() {
  local result=0
  if [ "$DRYRUN" = true ] || [ "$VERBOSE" = true ] || [ "$DEBUG" = true ] ; then
    echo "$*"
  fi

  if [ -z "$DRYRUN" ] || [ "$DRYRUN" = false ] || [ "$RUNANDPRINT" = true ] ; then
    eval "$*"
    result=$?
  fi

  return $result
}

message() {
  if [ "$DEBUG" = true ] && [ "$2" == "debug" ] ; then
    echo "$1"
  elif [ "$DRYRUN" = true ] || [ "$VERBOSE" = true ] || [ "$DEBUG" = true ] && [ "$2" != "debug" ] ; then
    echo "$1"
  fi
  if [ "$AUTO" = true ] && [ "$2" == "auto" ] ; then
    echo "$1"
  fi
}

# Works on a starting dir and a relative path. It will set a global ENV var
# called RELATIVE_PATH.  Example of a root path 2 dirs up from /home/user/test/dir1
#
# getRelativePath /home/user/test/dir1 '../..'
getRelativePath() {
  local cwd=$(pwd)
  cd $1/$2
  RELATIVE_PATH=$(pwd)
  cd $cwd
}

# From http://stackoverflow.com/questions/3685970/check-if-an-array-contains-a-value
containsElement() {
  local e
  for e in "${@:2}" ; do [[ "$e" == "$1" ]] && return 0 ; done
  return 1
}

containsElements() {
  local e
  for e in "${@:1}"; do
    if containsElement $e "${@:2}" ; then
      return 0
    fi
  done
  return 1
}

containsElementLike() {
  local e
  for e in "${@:2}" ; do [[ "$e" =~ $1 ]] && return 0 ; done
  return 1
}

containsElementsLike() {
  local e
  for e in "${@:1}"; do
    if containsElementLike $e "${@:2}" ; then
      return 0
    fi
  done
  return 1
}

# Setup sed based on our system
sedDetect() {
  local bsd_systems=( "Darwin" )
  SED_CMD=$(type -P sed)
  SED_I="-i"
  if containsElement $(uname -s) ${bsd_systems[@]} ; then
    SED_I="-i .bak"
  fi
}

usageStd() {
  local exit_code=$1
  local usage=$2
  local err=$3

  echo "$usage"

  if [ -n "$err" ] ; then
    echo "ERROR: $err"
    echo
  fi

  exit $exit_code
}

# K8s functions
# Use kubeInit() first in your script to setup the variables
# Set $NAMESPACE to desired k8s namespace
kubeInit() {
  NAMESPACE_OPT=
  [[ -n "$NAMESPACE" ]] && NAMESPACE_OPT="-n $NAMESPACE"
  K_CMD=$(type -P kubectl)
  K_GET="$K_CMD get $NAMESPACE_OPT"
}

# Check to make sure kubeInit() has run
kubeCheck() {
  if [ -z "$K_CMD" ] || [ -z "$K_GET" ] ; then
    kubeInit
  fi
}

# Use runOrPrint to execute kubectl, and apply the namespace
kube() {
  message "Starting kube()" "debug"

  kubeCheck
  runOrPrint "$K_CMD $* $NAMESPACE_OPT"

  message "Finishing kube()" "debug"
}

# Check if a k8s resource exists
kubeExists() {
  message "Starting kubeExists()" "debug"

  kubeCheck
  local exit_code=1
  if $K_GET $* > /dev/null 2>&1 ; then
    exit_code=0
  fi

  message "Finishing kubeExists()" "debug"
  return $exit_code
}

# Strip k8s metadata out of a json formatted stdin
# No extraneous messages in this function so we can redirect stdout
stripK8sMetadata() {
  mapfile -d '' jq_filter <<-END
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
      .spec.dataSourceRef,
      .spec.progressDeadlineSeconds,
      .spec.revisionHistoryLimit,
      .spec.template.metadata.annotations."kubectl.kubernetes.io/restartedAt",
      .spec.template.metadata.creationTimestamp,
      .spec.volumeName,
      .spec.volumeMode,
      .status
    )
END

  $(type -P jq) --exit-status --monochrome-output --raw-output --sort-keys 2>/dev/null "$jq_filter"
}

toggleK8sCron() {
  message "Starting toggleK8sCron()" "debug"

  local ret_val=0
  kubeCheck
  if kubeExists cronjobs $* ; then
    local value="true"
    if [ $($K_GET cronjobs $* -o jsonpath='{.spec.suspend}') == "true" ] ; then
      value="false"
    fi
    kube patch cronjobs $* -p "'{\"spec\": {\"suspend\": $value}}'"
  else
    echo "ERROR! Cronjob doesn't exist: $1"
    ret_val=1
  fi

  message "Finishing toggleK8sCron()" "debug"
  return $ret_val
}
