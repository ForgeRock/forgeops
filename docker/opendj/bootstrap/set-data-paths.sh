#!/usr/bin/env bash
# Set the paths to our database backends to use our persistent storage volume mounted on db/
# todo: Do we want to use commons config expressions here instead?

cd /opt/opendj 

echo "Setting backend database paths"

bin/dsconfig set-backend-prop \
    --offline --no-prompt \
    --backend-name ctsRoot \
    --set db-directory:data/db

bin/dsconfig set-backend-prop \
    --offline --no-prompt \
    --backend-name userRoot \
    --set db-directory:data/db

bin/dsconfig set-backend-prop \
    --offline  --no-prompt \
    --backend-name monitorUser \
    --set ldif-file:data/db/monitorUser/monitorUser.ldif

bin/dsconfig set-backend-prop \
    --offline --no-prompt \
    --backend-name adminRoot \
    --set ldif-file:data/db/admin/admin-backend.ldif

bin/dsconfig set-backend-prop \
    --offline --no-prompt \
    --backend-name rootUser \
    --set ldif-file:data/db/rootUser/rootUser.ldif

