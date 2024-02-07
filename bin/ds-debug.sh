#!/usr/bin/env bash
# Utility script to run commands inside a ds container
# This is an internal script provided for debugging purposes only and is not supported by ForgeRock.

POD_NAME="ds-idrepo-0"
POD_CREDENTIALS_FILE="/var/run/secrets/cloud-credentials-cache/gcp-credentials.json"

usage() {
  echo "Usage: $0 [-p|--pod-name POD_NAME] SUB_COMMAND [SUB_COMMAND_OPTIONS]"
  echo "Options:"
  echo "  -p, --pod-name       Name of DS pod. Default is ${POD_NAME}"
  echo "  SUB-COMMAND (run on DS pod) :"
  echo "    status             Display basic server information"
  echo "    rstatus            Check replication status"
  echo "    idsearch           Run ldapsearch on ou=identities base dn"
  echo "    monitor            Run ldapsearch on cn=monitor base dn"
  echo "    list-backups       List backups stored in a cloud bucket"
  echo "                       usage: $0 [-p|--pod-name POD_NAME] list-backups --backupLocation gs://BUCKET_PATH/POD_NAME"
  echo "    purge              Remove backups older than 12h"
  echo "                       usage: $0 [-p|--pod-name POD_NAME] purge --backupLocation gs://BUCKET_PATH/POD_NAME"
  echo ""
  echo "Note for list-backups and purge sub-commands :"
  echo "  - limitation : work with Google Storage. Could be updated to work with AKS, EKS,... storages"
  echo "  - DS pod must have Google Storage credentials file in ${POD_CREDENTIALS_FILE}"
  echo ""
  echo "Examples: $0 list-backups --backupLocation gs://my-bucket/ds-backup/project-1/site-1/ds-idrepo-0"
  echo "          $0 purge --backupLocation gs://my-bucket/ds-backup/project-1/site-1/ds-idrepo-0"
  echo "          $0 rstatus"
  echo "          $0 -p ds-idrepo-0 rstatus -X"
  exit 0
}

if [ "$#" -lt 1 ]; then
  usage
fi


# PARSING : First parse pod name
OPTIND="1"
if [ "${1}" == "-p" ] || [ "${1}" == "--pod-name"  ] ; then
  POD_NAME="${2}"
  shift
  shift
fi

# PARSING : get command name
ds_debug_custom_cmd="${*}"
cmd="$1"
shift
# PARSING : get command options (if any)
cmd_options="$*"

# All the backends we know about..
backends="ou=identities ou=tokens ou=am-config dc=openidm,dc=forgerock,dc=io"
dr_args=""
for b in $backends; do
  dr_args="$dr_args --baseDN $b"
done

setArgs() {
  pw=$(kubectl get secret ds-passwords -o jsonpath="{.data.${1}\\.pw}" | base64 --decode)
  bind_args="-w $pw -p $2"
}

kcmd() {
  echo "${*}"
  kubectl exec "${POD_NAME}" -it -- ${*}
}

checkKey() {
    kubectl exec "${POD_NAME}" -it -- ls ${POD_CREDENTIALS_FILE} > /dev/null 2>&1
    if [[ $? -eq 2 ]] ; then
      echo "error : looks like ${POD_NAME} does not have /var/run/secrets/cloud-credentials-cache/gcp-credentials.json"
      echo "        please copy the json credential file (to access to your backup bucket) into this pod location
      and rerun the script"
      exit 1
    fi
}

case "$cmd"  in
status)
  # Display basic server information
  setArgs dirmanager 4444
  kcmd status "${bind_args}" "${cmd_options}"
  ;;
rstatus)
  # Check replication status
  setArgs monitor 4444
  kcmd dsrepl status --showReplicas --showChangeLogs "${bind_args}" "${cmd_options}"
  ;;
idsearch)
  # List identities
  setArgs dirmanager 1389
  kcmd ldapsearch -D "uid=admin" "${bind_args}" --baseDN ou=identities "(objectclass=*)"
  ;;
monitor)
  # List monitor entries
  setArgs dirmanager 1389
  kcmd ldapsearch -D "uid=admin" "${bind_args}" --baseDN cn=monitor "(objectclass=*)"
   ;;
list-backups)
  # List backups
  checkKey
  kcmd dsbackup list --noPropertiesFile --storageProperty gs.credentials.path:${POD_CREDENTIALS_FILE} "${cmd_options}"
  ;;
purge)
  # Remove backups
  checkKey
  kcmd dsbackup purge --noPropertiesFile --storageProperty gs.credentials.path:${POD_CREDENTIALS_FILE}  --offline "${cmd_options}" --olderThan '12h'
    ;;
-h | --help)
  # Help
  usage
  ;;
*)
  set -x
  kubectl exec "${POD_NAME}" -it -- "${ds_debug_custom_cmd}"
;;
esac

# Sample commands to recover from known state
# https://backstage.forgerock.com/docs/ds/7/config-guide/replication.html#reinit-repl