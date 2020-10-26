#!/usr/bin/env bash
# Utility script to run commands inside a ds container
# This is an internal script provided for debugging purposes only and is not supported by ForgeRock.

# Get the uid=admin password
pw=$(kubectl get secret ds-passwords -o jsonpath="{.data.dirmanager\\.pw}" | base64 --decode)

pwd_args="-w $pw"
cmd="$1"
k="kubectl exec ds-0 -it --"

backends="ou=identities ou=tokens ou=am-config dc=openidm,dc=forgerock,dc=io"

dr_args=""

for b in $backends; do
  dr_args="$dr_args --baseDN $b"
done

disaster() {
  echo "Running disaster recovery procedure to reset change log db for $*"
  echo "Starting in 5 seconds. Kill this if you dont want to lose your changelog!"
  sleep 5
  kcmd  dsrepl start-disaster-recovery -X $pwd_args $*
  echo "About to run the end DR command..."
  kcmd  dsrepl end-disaster-recovery -X  $pwd_args $*
}

kcmd() {
  echo $*
  kubectl exec ds-0 -it -- $*
}

case "$cmd"  in
status)
 kcmd status $pwd_args
  ;;
dr)
  disaster $dr_args
  ;;
rstatus)
  kcmd dsrepl status $pwd_args
  ;;
idsearch)
  kcmd ldapsearch $pwd_args --baseDN ou=identities "(objectclass=*)"
  ;;
monitor)
   kcmd ldapsearch $pwd_args --baseDN cn=monitor "(objectclass=*)"
   ;;
*)
  kubectl exec ds-0 -it -- $* $pwd_args
esac

# Sample commands to recover from known state
# https://backstage.forgerock.com/docs/ds/7/config-guide/replication.html#reinit-repl