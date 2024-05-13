# Setup kubectl
kubeInit

# Shared global vars
CONFIG_DEFAULT_PATH=$SCRIPT_DIR/../../config

# Component lists
COMPONENTS_STD=(
  'am'
  'idm'
  'ig'
)

COMPONENTS_UI=(
  'ui'
  'admin-ui'
  'end-user-ui'
  'login-ui'
)

COMPONENTS_BUILD=(
  'ds'
)

COMPONENTS_INSTALL=(
  'amster'
  'base'
  'ds-cts'
  'ds-idrepo'
)

COMPONENTS_WAIT=('secrets')

# Old list
# COMPONENTS_WAIT=(
#   'ds'
#   'am'
#   'amster'
#   'idm'
#   'apps'
#   'secrets'
#   'ig'
# )

#############
# Functions #
#############

# Shared Functions
processArgs() {
  DEBUG=false
  DRYRUN=false
  VERBOSE=false

  # Vars that can be set in /path/to/forgeops/forgeops-ng.conf
  BUILD_PATH=${BUILD_PATH:-docker}
  KUSTOMIZE_PATH=${KUSTOMIZE_PATH:-kustomize-ng}
  NO_HELM=${NO_HELM:-false}
  NO_KUSTOMIZE=${NO_KUSTOMIZE:-false}
  PUSH_TO=${PUSH_TO:-}

  # Vars that cannot be set in /path/to/forgeops/forgeops-ng.conf
  AMSTER_RETAIN=10
  COMPONENTS=()
  CREATE_NAMESPACE=false
  DEP_SIZE=false
  ENV_NAME=
  FORCE=false
  RESET=false
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
      -k|--kustomize) KUSTOMIZE_PATH=$2; shift 2 ;;
      -n|--namespace) NAMESPACE=$2 ; shift 2 ;;
      -p|--config-profile) CONFIG_PROFILE=$2 ; shift 2 ;;
      -r|--push-to) PUSH_TO=$2 ; shift 2 ;;
      -s|--source) SOURCE=$2 ; shift 2 ;;
      -y|--yes) SKIP_CONFIRM=true ; shift ;;
      --reset) RESET=true ; shift ;;
      --ds-snapshots) DS_SNAPSHOTS="$2" ; shift 2 ;;
      --cdk) SIZE='cdk'; shift ;;
      --mini) SIZE='mini' ; shift ;;
      --small) SIZE='small' ; shift ;;
      --medium) SIZE='medium' ; shift ;;
      --large) SIZE='large' ; shift ;;
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

  # Make sure we have a working kubectl
  [[ ! -x $K_CMD ]] && usage 1 'The kubectl command must be installed and in your $PATH'

  # If nothing or all specified as a component, make sure all is the only component
  if [ -z "$COMPONENTS" ] || containsElement 'all' ; then
    COMPONENTS=( 'all' )
  fi
  if containsElement 'all' ${COMPONENTS[@]} && [ "${#COMPONENTS[@]}" -gt 1 ] ; then
    COMPONENTS=( 'all' )
  fi
  message "COMPONENTS=${COMPONENTS[*]}" "debug"

  if [[ "$KUSTOMIZE_PATH" =~ ^/ ]] ; then
    message "Kustomize path is a full path: $KUSTOMIZE_PATH" "debug"
  else
    message "Kustomize path is relative: $KUSTOMIZE_PATH" "debug"
    KUSTOMIZE_PATH=$ROOT_PATH/$KUSTOMIZE_PATH
  fi
  message "KUSTOMIZE_PATH=$KUSTOMIZE_PATH" "debug"

  if [ -z "$ENV_NAME" ] && [[ "$PROG" =~ apply ]] ; then
    ENV_NAME=demo
  elif [ -z "$ENV_NAME" ] ; then
    usage 1 'An environment name (--env-name) is required.'
  fi
  OVERLAY_PATH=$KUSTOMIZE_PATH/overlay/$ENV_NAME
  message "OVERLAY_PATH=$OVERLAY_PATH" "debug"

  if [[ "$BUILD_PATH" =~ ^/ ]] ; then
    message "Build path is a full path: $BUILD_PATH" "debug"
  else
    message "Build path is relative: $BUILD_PATH" "debug"
    BUILD_PATH=$ROOT_PATH/$BUILD_PATH
  fi
  message "BUILD_PATH=$BUILD_PATH" "debug"

  if [ -z "$NAMESPACE" ] ; then
    message "Namespace not given. Getting from kubectl config." "debug"
    NAMESPACE=$($K_CMD config view --minify | grep 'namespace:' | sed 's/.*namespace: *//')
  fi
  message "NAMESPACE=$NAMESPACE" "debug"

  if [ "$DEP_SIZE" = true ] || [ -n "$SIZE" ]; then
    if [[ ! "PROG" =~ generate ]] ; then
      deprecateSize
    fi
  fi
}

# Sort the components so base is either first or last
shiftBaseComponent() {
  message "Starting shiftBaseComponent()" "debug"

  local pos=$1
  [[ -z "$pos" ]] && usage 1 "shiftBaseComponent() requires a position (first or last)"

  if containsElement 'base' ${COMPONENTS[@]} && [ "${#COMPONENTS[@]}" -gt 1 ]; then
    local new_components=()
    [[ "$pos" == "first" ]] && new_components=( "base" )
    local c=

    for c in ${COMPONENTS[@]} ; do
      message "c = $c" "debug"
      [[ "$c" == "base" ]] && continue
      new_components+=( "$c" )
      message "new_components = ${new_components[*]}" "debug"
    done

    [[ "$pos" == "last" ]] && new_components+=( "base" )
    COMPONENTS=( "${new_components[@]}" )
  fi

  message "Finishing shiftBaseComponent()" "debug"
}

# Check our components to make sure they are valid
checkComponents() {
  message "Starting checkComponents()" "debug"

  for c in ${COMPONENTS[@]} ; do
    if containsElement $c ${COMPONENTS_VALID[@]} ; then
      message "Valid component: $c" "debug"
    else
      usage 1 "Invalid component: $c"
    fi
  done
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

# Deprecate functions
# These functions handle custom deprecation messages for deprecated features.
deprecateSize() {
  message "Starting deprecateSize()" "debug"

  cat <<- EOM
  The size flags have been deprecated in favor of the --overlay flag. The
  overlay flag accepts a full path to an overlay or a path relative to the
  kustomize/overlay directory.

  For now, the old size flags utilize the new overlay functionality. Please
  update your documentation, scripts, CI/CD pipelines, and anywhere else you
  call forgeops to use --overlay from here on out.
EOM
}
