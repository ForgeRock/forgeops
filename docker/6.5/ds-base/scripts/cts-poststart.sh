#!/usr/bin/env bash

LOG="k8s-lifecycle.log"
# Note -bindDn is intentionally ommited as using default othewise space in it causes issues
COMMON="--hostname localhost \
        --port 4444 \
        --bindPasswordFile ${DIR_MANAGER_PW_FILE} \
        --trustAll \
        --no-prompt"

FINISHED_STRING="ds-root-dse"

while true; do
  # Check to see if DS is up although by the time this search command is run
  # the directory is up and running :-).  So a sleep of 5s might suffice here
  OUTPUT=$(bin/ldapsearch -p 1389 -b "" -s base objectclass=*)
  if [[ "$OUTPUT" = *$FINISHED_STRING* ]]; then
    echo "=> DS has started" >> ${LOG}
    break
    echo "Waiting for DS to start..." >> ${LOG}
  fi
  sleep 5s
done

echo "Setting db-durability to low" >> ${LOG}
bin/dsconfig set-backend-prop \
    --backend-name amCts \
    --set db-durability:low \
    ${COMMON}

echo "Disabling file based access logger" >> ${LOG}
bin/dsconfig set-log-publisher-prop \
    --publisher-name File-Based\ Access\ Logger \
    --set enabled:false \
    ${COMMON}

echo "Deleting backend amIdentityStore" >> ${LOG}
bin/dsconfig delete-backend \
    --backend-name amIdentityStore \
    ${COMMON}

echo "Setting replication-purge-delay to 1 hour" >> ${LOG}
bin/ldapmodify -h localhost -p 1389 -D "cn=directory manager" -j ${DIR_MANAGER_PW_FILE} <<EOF
dn: cn=replication server,cn=Multimaster Synchronization,cn=Synchronization Providers,cn=config
changetype: modify
replace: ds-cfg-replication-purge-delay
ds-cfg-replication-purge-delay: 1 h
EOF

exit 0