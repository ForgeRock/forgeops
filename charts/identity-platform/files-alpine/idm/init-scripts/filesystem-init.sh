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
  # Escape for JSON interpolation below: a password containing " or \
  # would otherwise produce a malformed conf file and fail IDM's config
  # load with an opaque parse error.
  RCS_KEY=$(printf '%s' "$RCS_KEY" | sed 's/[\\"]/\\&/g')
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
  # Optional sample provisioner: an LDAP connector over the RCS targeting the
  # deployment's own DS idrepo (resolver props userstore.host / port /
  # basecontext, USERSTORE_PASSWORD from the ds-passwords secret). Gives the
  # admin UI a working Connectors page entry and a base for sync setup.
  if [ "${RCS_CONNECTOR_SERVER_PROVISIONER_ENABLED:-false}" = "true" ]; then
    RCS_PROV_NAME="${RCS_CONNECTOR_SERVER_PROVISIONER_NAME:-ds_ldap}"
    RCS_PROV_HOST="${RCS_CONNECTOR_SERVER_PROVISIONER_HOST:-&{userstore.host|ds-idrepo-0.ds-idrepo}}"
    RCS_PROV_PORT="${RCS_CONNECTOR_SERVER_PROVISIONER_PORT:-1636}"
    RCS_PROV_BASE="${RCS_CONNECTOR_SERVER_PROVISIONER_BASE:-&{userstore.basecontext|ou=identities}}"
    RCS_PROV_USER="${RCS_CONNECTOR_SERVER_PROVISIONER_USER:-&{userstore.user|uid=admin}}"
    printf '%s\n' \
'{' \
'  "enabled": true,' \
'  "connectorRef": {' \
'    "bundleName": "org.forgerock.openicf.connectors.ldap-connector",' \
'    "bundleVersion": "[1.5.0.0,1.6.0.0)",' \
'    "connectorName": "org.identityconnectors.ldap.LdapConnector",' \
'    "connectorHostRef": "'"$RCS_NAME"'"' \
'  },' \
'  "producerBufferSize": 100,' \
'  "connectorPoolingSupported": true,' \
'  "poolConfigOption": {' \
'    "maxObjects": 10,' \
'    "maxIdle": 10,' \
'    "maxWait": 150000,' \
'    "minEvictableIdleTimeMillis": 120000,' \
'    "minIdle": 1' \
'  },' \
'  "operationTimeout": {' \
'    "CREATE": -1,' \
'    "TEST": -1,' \
'    "SYNC": -1,' \
'    "SEARCH": -1' \
'  },' \
'  "configurationProperties": {' \
'    "principal": "'"$RCS_PROV_USER"'",' \
'    "credentials": "&{userstore.password|}",' \
'    "host": "'"$RCS_PROV_HOST"'",' \
'    "port": {"$int": "'"$RCS_PROV_PORT"'"},' \
'    "ssl": true,' \
'    "baseContexts": [' \
'      "'"$RCS_PROV_BASE"'"' \
'    ],' \
'    "uidAttribute": "entryUUID",' \
'    "readSchema": true,' \
'    "accountObjectClasses": [' \
'      "top",' \
'      "person",' \
'      "organizationalPerson",' \
'      "inetOrgPerson"' \
'    ],' \
'    "accountUserNameAttributes": [' \
'      "uid",' \
'      "cn",' \
'      "sAMAccountName"' \
'    ],' \
'    "passwordAttribute": "userPassword",' \
'    "useBlocks": true,' \
'    "blockSize": 100,' \
'    "usePagedResultControl": true' \
'  },' \
'  "objectTypes": {' \
'    "account": {' \
'      "id": "account",' \
'      "type": "object",' \
'      "nativeType": "__ACCOUNT__",' \
'      "properties": {' \
'        "dn": {"type": "string", "required": true, "nativeName": "__NAME__", "nativeType": "string"},' \
'        "uid": {"type": "string", "nativeName": "uid", "nativeType": "string"},' \
'        "cn": {"type": "string", "nativeName": "cn", "nativeType": "string"},' \
'        "sn": {"type": "string", "nativeName": "sn", "nativeType": "string"},' \
'        "mail": {"type": "string", "nativeName": "mail", "nativeType": "string"},' \
'        "objectClass": {"type": "array", "items": {"type": "string", "nativeType": "string"}, "nativeName": "objectClass", "nativeType": "string"}' \
'      }' \
'    }' \
'  },' \
'  "resultsHandlerConfig": {"enableAttributesToGetSearchResultsHandler": true},' \
'  "syncFailureHandler": {"maxRetries": 5, "postRetryAction": "logged-ignore"}' \
'}' > "/fbc/conf/provisioner.openicf-${RCS_PROV_NAME}.json"
    echo "Wrote sample LDAP provisioner conf 'provisioner.openicf-${RCS_PROV_NAME}.json' (via RCS $RCS_NAME)"
  fi
else
  # A stale registration file would keep pointing IDM at a (possibly
  # removed/rotated) RCS: remove it when the wiring is disabled or the
  # secret is gone. Only touch the files this script writes - a deployer
  # who ships their own connectorinfoprovider.json in /custom/config just
  # had it copied to /fbc/conf, and must not lose it to our cleanup.
  if [ ! -e /custom/config/org.forgerock.openidm.provisioner.openicf.connectorinfoprovider.json ]; then
    rm -f /fbc/conf/org.forgerock.openidm.provisioner.openicf.connectorinfoprovider.json 2>/dev/null || true
  fi
  if [ ! -e /custom/config/provisioner.openicf-"${RCS_PROV_NAME:-ds_ldap}".json ]; then
    rm -f /fbc/conf/provisioner.openicf-"${RCS_PROV_NAME:-ds_ldap}".json 2>/dev/null || true
  fi
fi

echo "Setting up writeable volume."
echo "Creating tmp"
mkdir -p /writeable/tmp
echo "Copying /opt/openidm"
mkdir -p /writeable/opt
cp -av /opt/openidm/ /writeable/opt/openidm
