#!/usr/bin/env bash
EXPORT_DIR="${EXPORT_DIR:-/var/tmp/amster}"

# List of realm entities to export.
realmEntities="OAuth2Clients IdentityGatewayAgents J2eeAgents WebAgents SoapStsAgents Policies CircleOfTrust Saml2Entity Applications"

# Create a temporary export folder.
# rm -fr $EXPORT_DIR
mkdir -p $EXPORT_DIR

# Create Amster export script.
cat > /tmp/do_export.amster <<EOF
connect -k  /var/run/secrets/amster/id_rsa $AMSTER_AM_URL
export-config --path $EXPORT_DIR --realmEntities '${realmEntities}' --globalEntities ' '
:quit
EOF

/opt/amster/amster /tmp/do_export.amster

echo "Exported files:"
ls -R /var/tmp/amster