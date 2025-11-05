#!/usr/bin/env bash
# Export dynamic config.

# Alive check
ALIVE="${AMSTER_AM_URL}/json/health/ready"

wait_for_am() {
  echo "Waiting for PingAM server at ${ALIVE}..."
  response="000"

	while true
	do
      echo "Trying ${ALIVE}"
      response=$(wget --server-response --tries=1 ${ALIVE} 2>&1 | grep "HTTP/1.1 200" | xargs)

      if [ "${response}" = "HTTP/1.1 200" ];
      then
         echo "AM web app is up"
         break
      fi

      echo "Will continue to wait..."
      sleep 5
   done
}

# Set PingAM url if not set
AMSTER_AM_URL=${AMSTER_AM_URL:-http://am:80/am}

EXPORT_DIR="${EXPORT_DIR:-/var/tmp/amster}"
mkdir -p $EXPORT_DIR

# List of realm entities to export.
if [[ "$1" == "full" ]]; then
    realmEntities=""
else
    realmEntities="--realmEntities 'OAuth2Clients IdentityGatewayAgents J2eeAgents WebAgents Policies CircleOfTrust Saml2Entity Applications'"
fi

# Create a temporary export folder.
mkdir -p $EXPORT_DIR

# Create Amster export script.
cat > /tmp/do_export.amster <<EOF
connect -k  /var/run/secrets/amster/id_rsa $AMSTER_AM_URL
export-config --path '$EXPORT_DIR' ${realmEntities}
:quit
EOF

wait_for_am

/opt/amster/amster /tmp/do_export.amster

echo "Exported files:"
ls -R /var/tmp/amster