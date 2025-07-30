# Setup kubectl
kubeInit

# Shared global vars
CONFIG_DEFAULT_PATH=$SCRIPT_DIR/../../config

# Component lists
COMPONENTS_ALL=('all' 'platform')

COMPONENTS_META=('apps' 'ds' 'ui' 'platform')

COMPONENTS_STD=(
  'am'
  'idm'
  'ig'
)

COMPONENTS_APPS=(
  'am'
  'amster'
  'idm'
)

COMPONENTS_UI=(
  'admin-ui'
  'end-user-ui'
  'login-ui'
)

COMPONENTS_DS=(
  'ds-cts'
  'ds-idrepo'
)

COMPONENTS_APPLY=(
  ${COMPONENTS_APPS[@]}
  ${COMPONENTS_DS[@]}
  ${COMPONENTS_UI[@]}
  'ig'
  'base'
  'all'
  ${COMPONENTS_META[@]}
)

COMPONENTS_PLATFORM=(
  'secrets'
  ${COMPONENTS_UI[@]}
  ${COMPONENTS_DS[@]}
  ${COMPONENTS_APPS[@]}
)

COMPONENTS_WAIT=(
   ${COMPONENTS_PLATFORM[@]}
   'ig'
   'all'
   ${COMPONENTS_META[@]}
)

COMPONENTS_PREREQS=(
  'cert-manager'
  'ingress'
  'secrets'
)

SUPPORTED_CONTAINER_ENGINES=('docker' 'podman')

#############
# Functions #
#############

# Shared Functions
processArgs() {
  DEBUG=false
  DRYRUN=false
  VERBOSE=false

  # Vars that can be set in /path/to/forgeops/forgeops.conf
  BUILD_PATH=${BUILD_PATH:-docker}
  KUSTOMIZE_PATH=${KUSTOMIZE_PATH:-kustomize}
  HELM_PATH=${HELM_PATH:-helm}
  NO_HELM=${NO_HELM:-false}
  NO_KUSTOMIZE=${NO_KUSTOMIZE:-false}
  IMAGE_REPO=${IMAGE_REPO:-}
  INGRESS=${INGRESS:-nginx}
  PUSH_TO=${PUSH_TO:-}
  QUIET=false
  SECRETS=${SECRETS:-secret-agent}
  UPGRADE=${UPGRADE:-false}

  # Vars that cannot be set in /path/to/forgeops/forgeops.conf
  AMSTER_RETAIN=10
  COMPONENTS=()
  COMPONENT_REQUIRED=true
  CREATE_NAMESPACE=false
  DEP_SIZE=false
  ENV_NAME=
  ENV_REQUIRED=${ENV_REQUIRED:-true}
  FORCE=false
  RESET=false
  RELEASE_NAME=
  SIZE=
  SKIP_CONFIRM=false

  # Setup prog for usage()
  PROG_NAME=$(basename $0)
  PROG="forgeops ${PROG_NAME}"

  while true; do
    case "$1" in
      -h|--help) usage 0 ;;
      -d|--debug) DEBUG=true ; shift ;;
      --dryrun) DRYRUN=true ; shift ;;
      -v|--verbose) VERBOSE=true ; shift ;;
      -a|--amster-retain) AMSTER_RETAIN=$2 ; shift 2 ;;
      -b|--build-path) BUILD_PATH=$2 ; shift 2 ;;
      -c|--create-namespace) CREATE_NAMESPACE=true ; shift ;;
      -e|--env-name) ENV_NAME=$2 ; shift 2 ;;
      -H|--helm-path) HELM_PATH=$2; shift 2 ;;
      -k|--kustomize-path) KUSTOMIZE_PATH=$2; shift 2 ;;
      -n|--namespace) NAMESPACE=$2 ; shift 2 ;;
      -p|--config-profile) CONFIG_PROFILE=$2 ; shift 2 ;;
      -r|--push-to) PUSH_TO=$2 ; shift 2 ;;
      -l|--release-name) RELEASE_NAME=$2 ; shift 2 ;;
      -s|--source) SOURCE=$2 ; shift 2 ;;
      -u|--upgrade) UPGRADE=true ; shift ;;
      -q|--quiet) QUIET=true ; shift ;;
      -y|--yes) SKIP_CONFIRM=true ; shift ;;
      --reset) RESET=true ; shift ;;
      --ds-snapshots) DS_SNAPSHOTS="$2" ; shift 2 ;;
      --cdk) SIZE='cdk'; shift ;;
      --mini) SIZE='mini' ; shift ;;
      --small) SIZE='small' ; shift ;;
      --medium) SIZE='medium' ; shift ;;
      --large) SIZE='large' ; shift ;;
      --haproxy) INGRESS='haproxy' ; shift ;;
      --secret-generator) SECRETS='secret-generator' ; shift ;;
      -f|--force|--fqdn)
        if [[ "$1" =~ "force" ]] || [[ "$2" =~ ^\- ]] || [[ "$2" == "" ]]; then
          FORCE=true
          shift
          message "FORCE=$FORCE" "debug"
        else
          FQDN=$2
          shift 2
          message "FQDN=$FQDN" "debug"
        fi
        ;;
      -t|--timeout|--tag)
        if [ "$PROG_NAME" == "build" ] ; then
          TAG=$2
        else
          TIMEOUT=$2
        fi
        shift 2
        ;;
      "") break ;;
      *) COMPONENTS+=( $1 ) ; shift ;;
    esac
  done

  message "DEBUG=$DEBUG" "debug"
  message "DRYRUN=$DRYRUN" "debug"
  message "VERBOSE=$VERBOSE" "debug"
  message "PROG=$PROG" "debug"

  getRelativePath $SCRIPT_DIR ../..
  ROOT_PATH=$RELATIVE_PATH
  message "ROOT_PATH=$ROOT_PATH" "debug"
  FORGEOPS_DATA=${FORGEOPS_DATA:-$ROOT_PATH}
  message "FORGEOPS_DATA=$FORGEOPS_DATA" "debug"

  # Make sure we have a working kubectl
  [[ ! -x $K_CMD ]] && usage 1 'The kubectl command must be installed and in your $PATH'

  if [ "$ENV_REQUIRED" = true ] && [ -z "$ENV_NAME" ] ; then
    usage 1 "You must provide -e|--env-name"
  fi

  if containsElement 'all' "${COMPONENTS[*]}" && [ "$PROG_NAME" != 'prereqs' ] ; then
    echo "The 'all' meta component has been deprecated in favor of 'platform'."
  fi

  # If nothing or platform specified as a component, make sure platform is the only component
  if [ -z "$COMPONENTS" ] || containsElements "${COMPONENTS_ALL[*]}" "${COMPONENTS[*]}" ; then
    if [ "$PROG_NAME" == 'prereqs' ] ; then
      COMPONENTS=( 'all' )
    else
      COMPONENTS=( 'platform' )
    fi
  fi
  message "COMPONENTS=${COMPONENTS[*]}" "debug"

  if [ "$ENV_REQUIRED" = false ] ; then
    message "An environment is not required" "debug"
  elif [ -z "$ENV_NAME" ] && [[ "$PROG" =~ apply ]] ; then
    ENV_NAME=demo
  elif [ -z "$ENV_NAME" ] ; then
    usage 1 'An environment name (--env-name) is required.'
  fi

  if [[ "$HELM_PATH" =~ ^/ ]] ; then
    message "Helm path is a full path: $HELM_PATH" "debug"
  else
    message "Helm path is relative: $HELM_PATH" "debug"
    HELM_PATH=$FORGEOPS_DATA/$HELM_PATH
  fi
  message "HELM_PATH=$HELM_PATH" "debug"

  if [[ "$KUSTOMIZE_PATH" =~ ^/ ]] ; then
    message "Kustomize path is a full path: $KUSTOMIZE_PATH" "debug"
  else
    message "Kustomize path is relative: $KUSTOMIZE_PATH" "debug"
    KUSTOMIZE_PATH=$FORGEOPS_DATA/$KUSTOMIZE_PATH
  fi
  message "KUSTOMIZE_PATH=$KUSTOMIZE_PATH" "debug"

  OVERLAY_ROOT=$KUSTOMIZE_PATH/overlay
  OVERLAY_PATH=$OVERLAY_ROOT/$ENV_NAME
  message "OVERLAY_PATH=$OVERLAY_PATH" "debug"

  if [[ "$BUILD_PATH" =~ ^/ ]] ; then
    message "Build path is a full path: $BUILD_PATH" "debug"
  else
    message "Build path is relative: $BUILD_PATH" "debug"
    BUILD_PATH=$FORGEOPS_DATA/$BUILD_PATH
  fi
  message "BUILD_PATH=$BUILD_PATH" "debug"

  if [ -z "$NAMESPACE" ] ; then
    message "Namespace not given. Getting from kubectl config." "debug"
    NAMESPACE=$($K_CMD config view --minify | grep 'namespace:' | sed 's/.*namespace: *//')
  fi
  message "NAMESPACE=$NAMESPACE" "debug"

  # Deprecations
  deprecateSize
}

# Sort the components so base is either first or last
shiftComponent() {
  message "Starting shiftComponent()" "debug"

  local component=$1
  local pos=$2
  [[ -z "$pos" ]] && usage 1 "shiftComponent() requires a position (first or last)"

  if containsElement $component "${COMPONENTS[*]}" && [ "${#COMPONENTS[@]}" -gt 1 ]; then
    local new_components=()
    [[ "$pos" == "first" ]] && new_components=( $component )
    local c=

    for c in ${COMPONENTS[@]} ; do
      message "c = $c" "debug"
      [[ "$c" == "$component" ]] && continue
      new_components+=( "$c" )
      message "new_components = ${new_components[*]}" "debug"
    done

    [[ "$pos" == "last" ]] && new_components+=( $component )
    COMPONENTS=( "${new_components[@]}" )
  fi

  message "Finishing shiftComponent()" "debug"
}

# Check our components to make sure they are valid
checkComponents() {
  message "Starting checkComponents()" "debug"

  for c in ${COMPONENTS[@]} ; do
    if containsElement $c "${COMPONENTS_VALID[*]}" ; then
      message "Valid component: $c" "debug"
    else
      usage 1 "Invalid component: $c"
    fi
  done
}

checkContainerEngine() {
  message "Starting checkContainerEngine()" "debug"

  CONTAINER_ENGINE=${CONTAINER_ENGINE:-docker}
  if ! containsElement $CONTAINER_ENGINE "${SUPPORTED_CONTAINER_ENGINES[*]}" ; then
    message "$CONTAINER_ENGINE has not been officially tested. Use at your own risk."
  fi

  message "Finishing checkContainerEngine()" "debug"
}

validateOverlay() {
  message "Starting validateOverlay() to validate $OVERLAY_PATH" "debug"

  if [ ! -d "$OVERLAY_PATH/image-defaulter" ] ; then
    cat <<- EOM
    ERROR: Missing $OVERLAY_PATH/image-defaulter.
    Please copy an image-defaulter into place, or run the container build
    process against this overlay.
EOM
  fi
}

expandComponent() {
  message "Starting expandComponent()" "debug"

  local component=$1
  local components=$2
  local new_components=()

  for c in ${COMPONENTS[@]} ; do
    if [ "$c" == "$component" ] ; then
      continue
    else
      new_components+=( "$c" )
    fi
  done

  for c in $components ; do
    if ! containsElement $c "${COMPONENTS[*]}" ; then
      new_components+=( "$c" )
    fi
  done

  COMPONENTS=( "${new_components[@]}" )
}

# Deprecate functions
# These functions handle custom deprecation messages for deprecated features.
deprecateSize() {
  message "Starting deprecateSize()" "debug"

  if [ "$DEP_SIZE" = true ] || [ -n "$SIZE" ]; then
    cat <<- EOM
The size flags have been deprecated in favor of the --overlay flag. The
overlay flag accepts a full path to an overlay or a path relative to the
kustomize/overlay directory.

For now, the old size flags utilize the new overlay functionality. Please
update your documentation, scripts, CI/CD pipelines, and anywhere else you
call forgeops to use --overlay from here on out.
EOM
  fi
}
