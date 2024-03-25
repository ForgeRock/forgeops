#!/usr/bin/env bash
EXPORT_DIR="${EXPORT_DIR:-/var/tmp/amster}"

# Create a temporary export folder.
mkdir -p /var/tmp/amster

# Create Amster export script.
cat > /tmp/do_export.amster <<EOF
connect -k  /var/run/secrets/amster/id_rsa http://am:80/am
export-config --path '${EXPORT_DIR}' --realmEntities '${REALM_ENTITIES}' --globalEntities ' '
:quit
EOF

/opt/amster/amster /tmp/do_export.amster
