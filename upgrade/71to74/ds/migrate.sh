#!/usr/bin/env bash

set -eo pipefail

# testing the commands
# set -x

# Grab our starting dir
start_dir=$(pwd)
# Figure out the dir we live in
SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
# Bring in our standard functions
source $SCRIPT_DIR/../../../bin/stdlib.sh
cd $start_dir

usage() {
    exit_code=$1
    err=$2
    prog=$(basename $0)
    cat <<EOF
Usage:
$prog [OPTIONS] COMMAND <TARGET> <REV>

Tool for migrating DS from 7.1 to 7.2 or higher. In 7.2+, we switch to using the
ds-operator to manage DS. This tool sets up a 7.1 installation without
ds-operator to be compatible with 7.2+ managed by ds-operator.

  OPTIONS:
    -h|--help                 : display usage and exit
    --debug                   : turn on debugging
    --dryrun                  : do a dry run
    -v|--verbose              : be verbose
    -n|--namespace            : specify namespace to work in

Requirements:
  * kubectl installed and in your path
  * kubeconfig pointed at correct cluster

Commands:
  patch
  patch-owner
  patch-service
  prime
  rollback
  secrets
  strategy

Rollbacks:
We use the `kubectl rollout` command to do the rollback. You pass the target
(idrepo or cts) and the version to roll back to. You'll need to use the following
commands to get the correct version for your targets.

kubectl rollout history sts ds-idrepo
kubectl rollout history sts ds-cts

Examples:
  Update secrets:
  $prog secrets

  Update strategy:
  $prog strategy idrepo
  $prog strategy cts

  Patch stateful set:
  $prog patch idrepo
  $prog patch cts

  Patch owner:
  $prog patch-owner idrepo
  $prog patch-owner cts

  Patch service:
  $prog patch-service idrepo
  $prog patch-service cts

  Prime DS PVCs:
  $prog prime idrepo-0
  $prog prime cts-0

  Rollback:
  $prog rollback idrepo 1

EOF

  if [ ! -z "$err" ] ; then
    echo "ERROR: $err"
    echo
  fi

  exit $exit_code
}

prime() {
    message "Entering prime()" "debug"

    [[ -z "$1" ]] && usage 1 "Missing prime target. Specify idrepo or cts."

    if $KUBECTL_CMD exec ds-${1} -- test -d data/config > /dev/null 2>&1 ;  then
        echo "data/ directory contains config. Data dir is ready.";

        return 0
    else
        echo "data/ directory missing config. Priming..."
    fi

    runOrPrint $KUBECTL_CMD exec ds-${1} -- cp -r {bak,config,ldif,logs} data
    runOrPrint $KUBECTL_CMD exec ds-${1} -- cp -ar secrets data
}

updateStrategy() {
    message "Entering updateStrategy()" "debug"

    [[ -z "$1" ]] && usage 1 "Missing strategy target. Specify idrepo or cts."

    runOrPrint "$KUBECTL_CMD patch sts ds-${1} --patch '{\"spec\": {\"updateStrategy\": {\"type\": \"OnDelete\"}}}'"
}

secrets() {
    message "Entering secrets()" "debug"
    # ca cert
    runOrPrint "$KUBECTL_CMD get secret platform-ca -o 'go-template={{index .data \"ca.pem\"}}' |base64 -d > cacrt.pem"

    # master key pair
    runOrPrint "$KUBECTL_CMD get secret ds -o 'go-template={{index .data \"master-key-pair-private.pem\"}}' |base64 -d > masterkey.pem"
    runOrPrint "$KUBECTL_CMD get secret ds -o 'go-template={{index .data \"master-key-pair.pem\"}}' |base64 -d > mastercrt.pem"
    runOrPrint "$KUBECTL_CMD create secret generic ds-master-keypair --from-file=ca.crt=cacrt.pem --from-file=tls.crt=mastercrt.pem --from-file=tls.key=masterkey.pem"

    # ssl key pair
    runOrPrint "$KUBECTL_CMD get secret ds -o 'go-template={{index .data \"ssl-key-pair-private.pem\"}}' |base64 -d > sslkey.pem"
    runOrPrint "$KUBECTL_CMD get secret ds -o 'go-template={{index .data \"ssl-key-pair.pem\"}}' |base64 -d > sslcrt.pem"
    runOrPrint "$KUBECTL_CMD create secret generic ds-ssl-keypair --from-file=ca.crt=cacrt.pem --from-file=tls.crt=sslcrt.pem --from-file=tls.key=sslkey.pem"

    # cleanup
    runOrPrint rm cacrt.pem
    runOrPrint rm masterkey.pem mastercrt.pem
    runOrPrint rm sslkey.pem sslcrt.pem
}

patch() {
    message "Entering patch()" "debug"

    [[ -z "$1" ]] && usage 1 "Missing patch target. Specify idrepo or cts."

    initPatch='[{ "op": "remove", "path": "/spec/template/spec/initContainers/1" }]'
    runOrPrint $KUBECTL_CMD patch sts ds-${1} --patch-file "patches/statefulset-${1}-new.yaml"
    runOrPrint "$KUBECTL_CMD patch sts ds-${1} --type='json' -p='$initPatch'"
}

patchOwnerRef() {
    message "Entering patchOwnerRef()" "debug"

    [[ -z "$1" ]] && usage 1 "Missing patch-owner target. Specify idrepo or cts."

    uid=$($KUBECTL_CMD get directoryservice ds-idrepo -o jsonpath='{.metadata.uid}')

    ! read -r -d '' stsPatch << EOM
[{
  "op": "add",
  "path": "/metadata/ownerReferences",
  "value": [{
        "apiVersion": "directory.forgerock.io/v1alpha1",
        "blockOwnerDeletion": true,
        "controller": true,
        "kind": "DirectoryService",
        "name": "'ds-${1}'",
        "uid": "'${uid}'"
  }]
}]
EOM

    stsPatch=$(echo $stsPatch | tr '\n' ' ') # Remove newlines before using
    runOrPrint "$KUBECTL_CMD patch statefulset ds-${1} --type='json' -p='$stsPatch'"
}

patchService() {
    message "Entering patchService" "debug"

    [[ -z "$1" ]] && usage 1 "Missing patch-owner target. Specify idrepo or cts."

    runOrPrint $KUBECTL_CMD patch svc ds-${1} --patch-file "patches/service-${1}-new.yaml"
}

rollback() {
    message "Entering rollback()" "debug"

    [[ -z "$1" ]] && usage 1 "Missing rollback target. Specify idrepo or cts."
    [[ -z "$2" ]] && usage 1 "Missing rollback revision. Specify a revision to rollback to."

    # rollback to a previous version of the sts
    runOrPrint $KUBECTL_CMD rollout undo sts/ds-${1} --to-revision=$2

    # kubectl rollout history sts/ds-idrepo
}

DEBUG=false
DRYRUN=false
VERBOSE=false

CMD=
TARGET=
REV=
KUBECTL_CMD=$(type -P kubectl)

while true; do
  case "$1" in
    -h|--help) usage 0 ;;
    --debug) DEBUG=true; shift ;;
    --dryrun) DRYRUN=true; shift ;;
    -v|--verbose) VERBOSE=true; shift ;;
    -n|--namespace) NAMESPACE=$2; shift 2 ;;
    "") break ;;
    *) CMD=$1
       TARGET=$2
       REV=$3
       break
       ;;
  esac
done

if [ -n "$NAMESPACE" ] ; then
  KUBECTL_CMD="$KUBECTL_CMD -n $NAMESPACE"
fi

message "Command given: $CMD" "debug"
message "Target given: $TARGET" "debug"
message "Revision = $REV" "debug"
message "KUBECTL_CMD = $KUBECTL_CMD" "debug"

case $CMD in
    patch)
        patch $TARGET # sts e.g. idrepo/cts
        ;;
    patch-owner)
        patchOwnerRef $TARGET
        ;;
    patch-service)
        patchService $TARGET
        ;;
    prime)
        prime $TARGET # pod id e.g. idrepo-0
        ;;
    rollback)
        rollback $TARGET $REV # sts e.g. idrepo/cts and revision number
        ;;
    secrets)
        secrets
        ;;
    strategy)
        updateStrategy $TARGET # sts e.g. idrepo/cts
        ;;
    *)
        usage 1 "Unrecognized command: $CMD"
        ;;
esac
