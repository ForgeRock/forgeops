#!/usr/bin/env bash
EXPORT_DIR="${EXPORT_DIR:-/var/tmp/amster}"

# List of realm entities to export.
realmEntities="OAuth2Clients IdentityGatewayAgents J2eeAgents WebAgents SoapStsAgents Policies CircleOfTrust Saml2Entity Applications"

# Create a temporary export folder.
rm -fr /var/tmp/amster
mkdir -p /var/tmp/amster

# Create Amster export script.
cat > /tmp/do_export.amster <<EOF
connect -k  /var/run/secrets/amster/id_rsa http://am:80/am
export-config --path $EXPORT_DIR --realmEntities '${realmEntities}' --globalEntities ' '
:quit
EOF

/opt/amster/amster /tmp/do_export.amster
