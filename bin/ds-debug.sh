#!/usr/bin/env bash
# Utility script to run commands inside a ds container
# This is an internal script provided for debugging purposes only and is not supported by ForgeRock.

usage() {
  echo "Usage: $0 status|rstatus|disaster|idsearch|monitor|list-backups|purge [pod name]"
  exit 1
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

disaster() {
  echo "Running disaster recovery procedure to reset change log db for $*"
  echo "Starting in 5 seconds. Kill this NOW if you dont want to lose your changelog!"
  sleep 5
  kcmd  dsrepl start-disaster-recovery -X $args $*
  echo "About to run the end DR command..."
  kcmd  dsrepl end-disaster-recovery -X  $args $*
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
disaster)
  # Run disaster recovery
  setArgs dirmanager 4444
  disaster $args
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
# https://backstage.forgerock.com/docs/ds/7/config-guide/replication.html#reinit-repl