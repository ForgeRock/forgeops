#!/usr/bin/env bash
# Utility script to run commands inside a ds container
# This is an internal script provided for debugging purposes only and is not supported by ForgeRock.

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 status|rstatus|disaster|monitor|list-backups|purge [pod name]"
  exit 1
fi
# Get the uid=admin password
pw=$(kubectl get secret ds-passwords -o jsonpath="{.data.dirmanager\\.pw}" | base64 --decode)

pwd_args="-w $pw"
cmd="$1"

BACKUP_LOCATION="gs://ds-operator-engineering-devops/ds-backup-test"

HOST="ds-0"

if [ ! -z "$2" ]; then
  HOST="$2"
fi

k="kubectl exec ds-0 -it --"

# All the backends we know about..
backends="ou=identities ou=tokens ou=am-config dc=openidm,dc=forgerock,dc=io"
dr_args=""
for b in $backends; do
  dr_args="$dr_args --baseDN $b"
done

disaster() {
  echo "Running disaster recovery procedure to reset change log db for $*"
  echo "Starting in 5 seconds. Kill this NOW if you dont want to lose your changelog!"
  sleep 5
  kcmd  dsrepl start-disaster-recovery -X $pwd_args $*
  echo "About to run the end DR command..."
  kcmd  dsrepl end-disaster-recovery -X  $pwd_args $*
}

kcmd() {
  echo $*
  kubectl exec $HOST -it -- $*
}

case "$cmd"  in
status)
 kcmd status $pwd_args
  ;;
disaster)
  disaster $dr_args
  ;;
rstatus)
  kcmd dsrepl status --showReplicas --showChangeLogs $pwd_args
  ;;
idsearch)
  kcmd ldapsearch $pwd_args --baseDN ou=identities "(objectclass=*)"
  ;;
monitor)
   kcmd ldapsearch $pwd_args --baseDN cn=monitor "(objectclass=*)"
   ;;
list-backups)
  kcmd dsbackup list --noPropertiesFile \
    --storageProperty gs.credentials.path:/var/run/secrets/cloud-credentials-cache/gcp-credentials.json \
    --backupLocation "${BACKUP_LOCATION}"
  ;;
purge)
kcmd dsbackup purge --noPropertiesFile --offline \
    --storageProperty gs.credentials.path:/var/run/secrets/cloud-credentials-cache/gcp-credentials.json \
    --backupLocation "${BACKUP_LOCATION}" \
    --olderThan '12h'
    ;;
*)
  kubectl exec ds-0 -it -- $* $pwd_args \
;;
esac

# Sample commands to recover from known state
# https://backstage.forgerock.com/docs/ds/7/config-guide/replication.html#reinit-repl