#!/usr/bin/env bash
# This is a temporary work around until file based config is integrated
# This removes the boot.json file if the config store (ds-idrepo) is not yet configured

TEST_DN="ou=sunIdentityRepositoryService,ou=services,ou=am-config"

AM_HOME=/home/forgerock/openam

# First we wait for ds-idrepo to be up

echo "Waiting for ds-idrepo to be available. Trying ds-idrepo:8080/alive endpoint"
while [[ "$(curl -s -o /dev/null -w ''%{http_code}'' ds-idrepo:8080/alive)" != "200" ]];
do
        sleep 5;
done
echo "ds-idrepo is responding"

copy_secrets() {
    mkdir -p $AM_HOME/var/audit
    SDIR=$AM_HOME/security/secrets/default
    KDIR=$AM_HOME/security/keystores
    mkdir -p $SDIR
    mkdir -p $KDIR
    echo "Copying bootstrap files for legacy AMKeyProvider"
    cp /var/run/secrets/am/boot/.storepass $SDIR
    cp /var/run/secrets/am/boot/.keypass $SDIR
    cp /var/run/secrets/am/boot/keystore.jceks $KDIR
    # Copy the amster key
    AMSTER_KEYS=$AM_HOME/security/keys/amster
    mkdir -p $AMSTER_KEYS
    cp /var/run/secrets/amster/authorized_keys $AMSTER_KEYS
}


copy_secrets


# Test the configstore to see if it contains a configuration. Return 0 if configured.
# This is not currently foolproof - it the ds-idrepo is not started yet the ldap search will also fail. This
# can result in util installer running again - which in most cases is fine - it will refresh the configuraition.

ldapsearch -w ${CFGDIR_PASS}  -D "uid=admin" -A -H "ldap://ds-idrepo-0.ds-idrepo:1389" -l 20 -b "$TEST_DN"  > /dev/null 2>&1
status=$?
echo "Is configured exit status is $status"
if [ $status -ne 0 ]; then
    echo "Looks like ds-idrepo is not configured. I will remove boot.json"
    rm $AM_HOME/config/boot.json
else
    echo "ds-idrepo configured - keeping boot.json"


fi

# Disable access logs and set the secure cookie
export CATALINA_OPTS="$CATALINA_OPTS -DtomcatAccessLogDir=/dev -DtomcatAccessLogFile=null -DtomcatSecureLoadBalancer=true"

exec catalina.sh run