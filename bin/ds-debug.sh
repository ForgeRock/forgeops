#!/usr/bin/env bash
# Utility script to run commands inside a ds container
# This is an internal script provided for debugging purposes only and is not supported by ForgeRock.

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

cmd="$1"

BACKUP_LOCATION="gs://ds-operator-engineering-devops/ds-backup-test"

HOST="ds-idrepo-0"

if [ ! -z "$2" ]; then
  HOST="$2"
fi

# All the backends we know about..
backends="ou=identities ou=tokens ou=am-config dc=openidm,dc=forgerock,dc=io"
dr_args=""
for b in $backends; do
  dr_args="$dr_args --baseDN $b"
done

setArgs() {
  pw=$(kubectl get secret ds-passwords -o jsonpath="{.data.${1}\\.pw}" | base64 --decode)
  args="-w $pw -p $2"
}

kcmd() {
  echo $*
  kubectl exec $HOST -it -- $*
}

case "$cmd"  in
status)
  # Display basic server information
  setArgs dirmanager 4444
  kcmd status $args
  ;;
rstatus)
  # Check replication status
  setArgs monitor 4444
  kcmd dsrepl status --showReplicas --showChangeLogs $args
  ;;
idsearch)
  # List identities
  setArgs dirmanager 1389
  kcmd ldapsearch -D "uid=admin" $args --baseDN ou=identities "(objectclass=*)"
  ;;
monitor)
  # List monitor entries
  setArgs dirmanager 1389
  kcmd ldapsearch -D "uid=admin" $args --baseDN cn=monitor "(objectclass=*)"
   ;;
list-backups)
  # List backups
  kcmd dsbackup list --noPropertiesFile \
    --storageProperty gs.credentials.path:/var/run/secrets/cloud-credentials-cache/gcp-credentials.json \
    --backupLocation "${BACKUP_LOCATION}"
  ;;
purge)
  # Remove backups
  kcmd dsbackup purge --noPropertiesFile --offline \
    --storageProperty gs.credentials.path:/var/run/secrets/cloud-credentials-cache/gcp-credentials.json \
    --backupLocation "${BACKUP_LOCATION}" \
    --olderThan '12h'
    ;;
-h)
  # Help
  usage
  ;;
*)
  kubectl exec $HOST -it -- $* $args \
;;
esac

# Sample commands to recover from known state
# https://backstage.forgerock.com/docs/ds/7.4/config-guide/repl-init.html