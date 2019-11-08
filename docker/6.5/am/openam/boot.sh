#!/usr/bin/env bash
# This is a temporary work around until file based config is integrated
# This removes the boot.json file if the config store (ds-idrepo) is not yet configured
#set -x

if [ "$#" -ne 1 ]; then
  exec $*
fi


TEST_DN="ou=sunIdentityRepositoryService,ou=services,ou=am-config"

# First we wait for ds-idrepo to be up

echo "Waiting for ds-idrepo to be available. Trying ds-idrepo:8080/alive endpoint"
while [[ "$(curl -s -o /dev/null -w ''%{http_code}'' ds-idrepo:8080/alive)" != "200" ]]; 
do 
        sleep 5; 
done
echo "ds-idrepo is responding"

# Test the configstore to see if it contains a configuration. Return 0 if configured.
# This is not currently foolproof - it the ds-idrepo is not started yet the ldap search will also fail. This
# can result in util installer running again - which in most cases is fine - it will refresh the configuraition.

SVC="ou=services,$BASE_DN"
r=$(ldapsearch -w password  -D "cn=Directory Manager" -A -H "ldap://ds-idrepo:1389" -s base -l 20 -b "$TEST_DN"  > /dev/null 2>&1)
status=$?
echo "Is configured exit status is $status"

# Remove the config location - we generate as required
rm -rf /home/forgerock/.openamcfg

# Remove the config location - we generate as required
rm -rf /home/forgerock/.openamcfg

if [ $status -ne 0 ]; then
    echo "Looks like ds-idrepo is not configured. I will remove boot.json"
    rm /home/forgerock/openam/boot.json
else
    echo "ds-idrepo configured - keeping boot.json"
    echo "Making log path to avoid audit service startup error "
    mkdir -p /home/forgerock/openam/am/log
    mkdir -p /home/forgerock/openam/am/debug
    echo "Copying bootstrap files for legacy AMKeyProvider"
    cp /var/run/secrets/am/boot/.storepass /home/forgerock/openam/am
    cp /var/run/secrets/am/boot/.keypass /home/forgerock/openam/am
    cp /var/run/secrets/am/boot/keystore.jceks /home/forgerock/openam/am

    echo "Generating .openamcfg"
    mkdir -p  /home/forgerock/.openamcfg
    echo "/home/forgerock/openam"  > /home/forgerock/.openamcfg/AMConfig_usr_local_tomcat_webapps_am_

fi

exec catalina.sh run 