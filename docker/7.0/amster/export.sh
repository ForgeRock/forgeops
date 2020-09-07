#!/usr/bin/env bash

# List of realm entities to export.
realmEntities="OAuth2Clients IdentityGatewayAgents J2eeAgents WebAgents SoapStsAgents OIDCClient Policies CircleOfTrust Saml2Entity"

# Create a temporary export folder.
rm -fr /var/tmp/amster
mkdir -p /var/tmp/amster

# Create Amster export script.
cat > /tmp/do_export.amster <<EOF
connect -k  /var/run/secrets/amster/id_rsa http://am:80/am
export-config --path /var/tmp/amster --realmEntities '${realmEntities}' --globalEntities ' '
:quit
EOF

/opt/amster/amster /tmp/do_export.amster
