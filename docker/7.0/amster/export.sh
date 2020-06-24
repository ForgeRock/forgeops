#!/usr/bin/env bash
# TODO - create an job that exports the dynamic config

rm -fr /var/tmp/amster
mkdir -p /var/tmp/amster

# Create Amster export script.
cat > /tmp/do_export.amster <<EOF
connect -k  /var/run/secrets/amster/id_rsa http://am:80/am
export-config --path /var/tmp/amster --realmEntities 'OAuth2Clients IdentityGatewayAgents' --globalEntities ' '
:quit
EOF

/opt/amster/amster /tmp/do_export.amster
