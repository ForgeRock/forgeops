#!/usr/bin/env bash

# Checking idrepo store is up
echo "Waiting for ds-idrepo-0 to be available. Trying /alive endpoint"
while [[ "$(curl -s -o /dev/null -w ''%{http_code}'' ds-idrepo-0.ds-idrepo:8080/alive)" != "200" ]];
do
        sleep 5;
done
echo "ds-idrepo-0 is responding"


# Set the DS passwords for each store
if [ -f "/opt/opendj/ds-passwords.sh" ]; then
    echo "Setting random DS passwords script..."
    /opt/opendj/ds-passwords.sh
    if [ $? -ne 0 ]; then
        echo "ERROR: Pre install script failed"
        exit 1
    fi
fi

# Apply the new ldap config entries
/opt/opendj/bin/ldapmodify -c \
    -D uid=admin \
    -j /var/run/secrets/opendj-passwords/dirmanager.pw \
    -h ds-idrepo-0.ds-idrepo \
    -p 1389 \
    /opt/opendj/external-am-datastore.ldif
