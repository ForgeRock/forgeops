#!/usr/bin/env bash
# This runs as a Kubernetes job. It runs in a DS image, but the instance is not part
# of the ds cluster itself. This job should exit after completion.
# This is where you set up replication or schedule backup.

# dsreplication wants a local directory server installed - even if it is talking to a remote node.
/opt/opendj/setup directory-server\
  -p 1389 \
  --adminConnectorPort 4444 \
  --baseDN "${BASE_DN}" -h "${FQDN}" \
  --rootUserPasswordFile "${DIR_MANAGER_PW_FILE}" \
  --acceptLicense \
  ${INIT_OPTION} || (echo "Setup failed, will sleep for debugging"; sleep 10000)


./bootstrap/replicate-ds2ds.sh

./bootstrap/schedule-backup.sh



