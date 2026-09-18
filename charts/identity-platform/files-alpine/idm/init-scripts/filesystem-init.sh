#!/bin/sh

if [ -d /fbc/conf ]; then
  echo "Existing openidm configuration found. Skipping copy."
elif [ -d /custom/config ]; then
  echo "Found config in custom volume."
  cd /opt/openidm
  cp -rv ui conf script /fbc
  # Deployer-provided configuration wins: drop the pristine-conf marker so
  # the image's apply-config-profile.sh never overlays the profile on top.
  rm -f /fbc/conf/.pristine-zip-conf
  cp -av /custom/config/* /fbc/
else
  echo "Copying docker image configuration files to the shared volume"
  cd /opt/openidm
  cp -rv ui conf script /fbc
fi

# Single-image runtime mode: when the deployment runs the image in forgeops
# mode, apply the CONFIG_PROFILE deployment conf over the conf the main
# container will read (the fbc volume). Pass /fbc as the home so the overlay
# lands in /fbc/conf; the helper is a no-op unless IMAGE_MODE=forgeops and
# the conf is still the pristine maven-build conf. The standalone (no fbc
# volume) path is covered by the image entrypoint calling the same helper
# with the default home.
if [ -d /fbc ]; then
  /opt/openidm/bin/apply-config-profile.sh /fbc || true
fi

# Out-of-the-box Remote Connector Server (RCS) wiring: when the platform.rcs
# values enable it AND the rcs-key secret is mounted (its presence means the
# charts/rcs release is deployed in this namespace), register the RCS with
# IDM's connector info provider by writing the pid-named conf file. The file
# is re-written on every boot so a changed key/host is picked up; when the
# secret is absent nothing is written and IDM keeps its defaults. The
# secret's RCS_KEY_PASSWORD is the plaintext shared password — what IDM's
# "key" config field must hold (IDM sends it as the Basic-auth password and
# the RCS compares its sha1-b64 hash). It is config-encrypted at conf load,
# so the plaintext copy lives only inside the init-time volume.
if [ "${RCS_CONNECTOR_SERVER_ENABLED:-false}" = "true" ] \
   && [ -s /rcs-secrets/RCS_KEY_PASSWORD ] && [ -d /fbc/conf ]; then
  RCS_HOST="${RCS_CONNECTOR_SERVER_HOST:-rcs.${NAMESPACE}.svc.cluster.local}"
  RCS_PORT="${RCS_CONNECTOR_SERVER_PORT:-8759}"
  RCS_NAME="${RCS_CONNECTOR_SERVER_NAME:-rcs-0}"
  RCS_USE_SSL="${RCS_CONNECTOR_SERVER_USE_SSL:-false}"
  RCS_KEY=$(cat /rcs-secrets/RCS_KEY_PASSWORD)
  printf '%s\n' \
'{' \
'  "connectorsLocation": "connectors",' \
'  "remoteConnectorServers": [' \
'    {' \
'      "name": "'"$RCS_NAME"'",' \
'      "enabled": true,' \
'      "host": "'"$RCS_HOST"'",' \
'      "port": '"$RCS_PORT"',' \
'      "useSSL": '"$RCS_USE_SSL"',' \
'      "principal": "anonymous",' \
'      "websocketPath": "openicf",' \
'      "timeout": 0,' \
'      "key": "'"$RCS_KEY"'"' \
'    }' \
'  ]' \
'}' > /fbc/conf/org.forgerock.openidm.provisioner.openicf.connectorinfoprovider.json
  echo "Registered Remote Connector Server '$RCS_NAME' at $RCS_HOST:$RCS_PORT"
else
  # A stale registration file would keep pointing IDM at a (possibly
  # removed/rotated) RCS: remove it when the wiring is disabled or the
  # secret is gone.
  rm -f /fbc/conf/org.forgerock.openidm.provisioner.openicf.connectorinfoprovider.json 2>/dev/null || true
fi

echo "Setting up writeable volume."
echo "Creating tmp"
mkdir -p /writeable/tmp
echo "Copying /opt/openidm"
mkdir -p /writeable/opt
cp -av /opt/openidm/ /writeable/opt/openidm
