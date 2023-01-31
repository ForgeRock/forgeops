#!/usr/bin/env bash

# Set AM url if not set
AMSTER_AM_URL=${AMSTER_AM_URL:-http://am:80/am}

# Create a temporary export folder.
EXPORT_DIR="${EXPORT_DIR:-/var/tmp/amster}"
mkdir -p $EXPORT_DIR

# List of realm entities to export.
if [[ "$1" == "full" ]]; then
    realmEntities=""
else
    realmEntities="--realmEntities 'OAuth2Clients IdentityGatewayAgents J2eeAgents WebAgents SoapStsAgents Policies CircleOfTrust Saml2Entity Applications TrustedJwtIssuer'"
fi

# Create Amster export script.
cat > /tmp/do_export.amster <<EOF
connect -k  /var/run/secrets/amster/id_rsa $AMSTER_AM_URL
export-config --path '$EXPORT_DIR' ${realmEntities}
:quit
EOF

/opt/amster/amster /tmp/do_export.amster

echo "Exported files:"
ls -R /var/tmp/amster
