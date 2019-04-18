#!/usr/bin/env bash
# This is a temporary work around until file based config is integrated
# This removes the boot.json file if the config store (idrepo) is not yet configured

TEST_DN="ou=sunIdentityRepositoryService,ou=services,ou=am-config"

# Test the configstore to see if it contains a configuration. Return 0 if configured.
# This is not currently foolproof - it the idrepo is not started yet the ldap search will also fail. This
# can result in util installer running again - which in most cases is fine - it will refresh the configuraition.
SVC="ou=services,$BASE_DN"
r=$(ldapsearch -w password  -D "uid=admin" -A -H "ldap://idrepo:1389" -s base -l 20 -b "$TEST_DN"  > /dev/null 2>&1)
status=$?
echo "Is configured exit status is $status"
if [ $status -ne 0 ]; then 
    echo "Looks like idrepo is not configured. I will remvove boot.json"
    rm /home/forgerock/openam/boot.json
else
    echo "idrepo configured - keeping boot.json"
fi

exec catalina.sh run 