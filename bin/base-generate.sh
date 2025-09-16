#!/usr/bin/env bash
# Generate a set of kustomize base resources from the helm chart
#set -oe pipefail

# Grab our starting dir
start_dir=$(pwd)
# Figure out the dir we live in
SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
# Bring in our standard functions
source $SCRIPT_DIR/../lib/shell/stdlib.sh
cd "${start_dir}"

getRelativePath $SCRIPT_DIR ..
ROOT_PATH=$RELATIVE_PATH
message "ROOT_PATH=$ROOT_PATH" "debug"

usage() {
    exit_code=$1
    err=$2
    prog=$(basename $0)
    cat <<EOM
Usage: $prog [OPTIONS] ACTION RESTORE_TARGET

Generate a set of kustomize base resources from the helm chart. The script will
look through the kustomize/base directory for directories that have a values
file. It will run the helm chart with those values and output them to the
resources file.

  OPTIONS:
    -h|--help                        : display usage and exit
    --debug                          : enable debugging output
    --dryrun                         : do a dry run
    -v|--verbose                     : be verbose
    -f|--values ValuesFileName       : values file name to look for (default: $VALUES_FILE_DEF)
    -k|--kustomize KustomizePath     : path to kustomize dir (default: $KUSTOMIZE_PATH_DEF)
    -n|--namespace NAMESPACE         : namespace to work in
    -r|--resources ResourceFileName  : resource file name to output to (default: $RESOURCES_FILE_DEF)
    -s|--source (local|remote)       : use local or remote chart (default: local)
    -V|--chartver ChartVersion       : version of the chart to use (default: $CHART_VER_DEF)

Requirements:
  * helm installed
  * yq (mikefarah)

Notes:
  * sources
    * local: charts dir in this repo
    * remote: $CHART

Examples:
  Generate new base using defaults:
  $prog

  Generate using specific namespace:
  $prog -n stage

  Use custom values and resources files:
  $prog -f val.yml -r res.yml

  Use an alternate chart version:
  $prog -V 7.3

EOM

  if [ ! -z "$err" ] ; then
    echo "ERROR: $err"
    echo
  fi

  exit $exit_code
}

stripTag() {
  message "Starting stripTag()" "debug"

  local file=$1
  message "Stripping image tags from ${file}" "debug"
  if grep -q 'image:' $file ; then
    message "Found image line in $file" "debug"
    local sed_opts='-i'
    if [ "$(uname -o)" == "Darwin" ] ; then
      sed_opts="-i ''"
    fi
    runOrPrint "sed $sed_opts -e 's/\(image:\) \"\([-a-z]*\):.*$/\1 \2/' ${file}"
    runOrPrint "$YQ_CMD -i eval -P 'del(.spec.template.metadata.annotations.deployment-date)' $file"
  fi

  message "Finishing stripTag()" "debug"
}

pruneDir() {
  local dir=$1
  local kust_file="kustomization.yaml"
  local kust_path="$dir/$kust_file"
  local values_regex='^values'
  if [ -f "$kust_path" ] ; then
    resources=$(yq eval '.resources' $kust_path | sed -e 's/^-//')
    cd $template_path
    for f in $dir/* ; do
      [[ ! -f $f ]] && continue # Skip if not a file
      file=$(basename $f)
      if [[ "$file" =~ $values_regex ]] || [ "$file" == "$kust_file" ] ; then
        continue
      fi
      if containsElement "$file" "$resources" ; then
        stripTag "$f"
      else
        rm $f
      fi
    done
  fi
}

rmChart() {
  local dir=$1
  local chart_path="$dir/$CHART_NAME"
  if [ -d "$chart_path" ] ; then
    echo "Removing $chart_path"
    runOrPrint "rm -rf $chart_path"
  fi

}

# Get the currently running service definition
processDir() {
  message "Starting processDir()" "debug"

  local dir=$1
  local base_values_opt=""
  if [ -n "$BASE_VALUES_FILE" ] ; then
    base_values_opt="-f $BASE_VALUES_FILE"
  fi
  for d in $dir/* ; do
    [[ ! -d $d ]] && continue # Skip if not a dir

    if [ -f $d/$VALUES_FILE ] ; then
      message "Found $VALUES_FILE in ${d%*/}" "debug"
      local output_opt="--output-dir $d"
      local override_opt=
      [[ -f "$d/$VALUES_OVERRIDE" ]] && override_opt="-f $d/$VALUES_OVERRIDE"
      rmChart "$d"
      echo "Generating $d templates"
      runOrPrint "$HELM_CMD template $CHART_NAME $HELM_OPTS $output_opt $base_values_opt -f $d/$VALUES_FILE $override_opt > /dev/null 2>&1"
      pruneDir "$d"
      rmChart "$d"
      processDir "${d%*/}"
    else
      message "Didn't find $VALUES_FILE in ${d%*/}" "debug"
      processDir ${d%*/}
    fi
  done

  message "Finishing processDir()" "debug"
}

# Defaults
DEBUG=false
DRYRUN=false
VERBOSE=false

HELM_CMD=$(type -P helm)
YQ_CMD=$(type -P yq)

CHART="oci://us-docker.pkg.dev/forgeops-public/charts"
CHART_NAME="identity-platform"
CHART_OUTPUT_PATH="$CHART_NAME/templates"
CHART_VER_DEF="1.0.0"
CHART_VER=
CHART_SOURCE="local"
KUSTOMIZE_PATH_DEF=$ROOT_PATH/kustomize
KUSTOMIZE_PATH=
NAMESPACE_DEF="prod"
NAMESPACE=
RESOURCES_FILE_DEF=resources.yaml
RESOURCES_FILE=
VALUES_FILE_DEF=values.yaml
VALUES_FILE=
VALUES_OVERRIDE_DEF=values-override.yaml
VALUES_OVERRIDE=

while true; do
  case "$1" in
    -h|--help) usage 0 ;;
    --debug) DEBUG=true; shift ;;
    --dryrun) DRYRUN=true; shift ;;
    -v|--verbose) VERBOSE=true; shift ;;
    -f|--file) VALUES_FILE=$2; shift 2 ;;
    -F|--override) VALUES_OVERRIDE=$2; shift 2 ;;
    -k|--kustomize) KUSTOMIZE_PATH=$2; shift 2 ;;
    -n|--namespace) NAMESPACE=$2; shift 2 ;;
    -r|--resources) RESOURCES_FILE=$2; shift 2 ;;
    -s|--source) CHART_SOURCE=$2; shfit 2 ;;
    -V|--chartver) CHART_VER=$2; shift 2 ;;
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

message "CHART=$CHART" "debug"
message "CHART_NAME=$CHART_NAME" "debug"

# Set variable defaults if not provided
CHART_VER=${CHART_VER:-$CHART_VER_DEF}
message "CHART_VER=$CHART_VER" "debug"
KUSTOMIZE_PATH=${KUSTOMIZE_PATH:-$KUSTOMIZE_PATH_DEF}
message "KUSTOMIZE_PATH=$KUSTOMIZE_PATH" "debug"
BASE_PATH="$KUSTOMIZE_PATH/base"
message "BASE_PATH=$BASE_PATH" "debug"
RESOURCES_FILE=${RESOURCES_FILE:-$RESOURCES_FILE_DEF}
message "RESOURCES_FILE=$RESOURCES_FILE" "debug"
VALUES_FILE=${VALUES_FILE:-$VALUES_FILE_DEF}
message "VALUES_FILE=$VALUES_FILE" "debug"
VALUES_OVERRIDE=${VALUES_OVERRIDE:-$VALUES_OVERRIDE_DEF}
message "VALUES_OVERRIDE=$VALUES_OVERRIDE" "debug"
NAMESPACE=${NAMESPACE:-$NAMESPACE_DEF}
message "NAMESPACE=$NAMESPACE" "debug"

VERSION_OPT="--version $CHART_VER"
NAMESPACE_OPT="-n $NAMESPACE"

if [ ! -x "$YQ_CMD" ] ; then
  echo "ERROR! mikefarah yq is not installed. Install it and run command again."
  exit 1
fi

if [ "$CHART_SOURCE" == "local" ] ; then
  HELM_OPTS="$SCRIPT_DIR/../charts/$CHART_NAME $NAMESPACE_OPT"
else
  HELM_OPTS="$CHART/$CHART_NAME $NAMESPACE_OPT $VERSION_OPT"
fi

if [[ "$KUSTOMIZE_PATH" =~ ^/ ]] ; then
  message "Kustomize path is a full path: $KUSTOMIZE_PATH" "debug"
else
  message "Kustomize path is relative: $KUSTOMIZE_PATH" "debug"
  KUSTOMIZE_PATH=$ROOT_PATH/$KUSTOMIZE_PATH
fi

if [ ! -e "$KUSTOMIZE_PATH" ] ; then
  usage 1 "Kustomize path ($KUSTOMIZE_PATH) doesn't exist."
fi

if [ ! -d "$KUSTOMIZE_PATH" ] ; then
  usage 1 "Kustomize path ($KUSTOMIZE_PATH) is not a directory."
fi

BASE_VALUES_FILE=""
if [ -f "$BASE_PATH/$VALUES_FILE" ] ; then
  BASE_VALUES_FILE="$BASE_PATH/$VALUES_FILE"
elif [ -f "$BASE_PATH/$VALUES_FILE_DEF" ] ; then
  BASE_VALUES_FILE="$BASE_PATH/$VALUES_FILE_DEF"
fi

processDir "$BASE_PATH"
