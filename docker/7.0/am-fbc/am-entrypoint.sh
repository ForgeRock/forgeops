#!/usr/bin/env bash

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
    rm -f $SDIR/.storepass $SDIR/.keypass
    cp /var/run/secrets/am/boot/.storepass $SDIR
    cp /var/run/secrets/am/boot/.keypass $SDIR
    cp /var/run/secrets/am/boot/keystore.jceks $KDIR
}

copy_secrets

# TODO: Switch to service account passwords once we get this all working
# For now - use uid=admin
# Csv list of ds servers for the repo. Use separate variables here in case we
# want to split the user store / config store in the future.
export DS_CFGSTORE_SERVERS=${DS_CFGSTORE_SERVERS:-"ds-idrepo-0.ds-idrepo:1389"}
export DS_USERSTORE_SERVERS=${DS_USERSTORE_SERVERS:-"ds-idrepo-0.ds-idrepo:1389"}
export DS_CTS_SERVERS=${DS_CTS_SERVERS:-"ds-cts-0.ds-cts:1389"}
# Policy store defaults to idrepo
export POLICY_LDAP_SERVERS="$DS_CFGSTORE_SERVERS";

# CTS user service account
export CTS_USER_DN="uid=openam_cts,ou=admins,ou=famrecords,ou=openam-session,ou=tokens"
export CTS_PASSWORD="$CTSUSR_PASS"

export CFG_USER_DN="uid=am-config,ou=admins,ou=am-config"
export CFG_USER_PASSWORD="$CFGUSR_PASS"

#export CFG_USER_DN="uid=admin"
#export CFG_USER_PASSWORD="$CFGDIR_PASS"

# Rename these in the secret generator
export USERSTORE_ADMIN_DN=${USERSTORE_ADMIN_DN:-"uid=am-identity-bind-account,ou=admins,ou=identities"}
export USERSTORE_PASSWORD="$USRUSR_PASS"

# Try hard coding see if it works
#export USERSTORE_ADMIN_DN="uid=admin"
#export USERSTORE_PASSWORD="$USRDIR_PASS"

export POLICY_DN=$CFG_USER_DN;
export POLICY_PASSWORD=$CFG_USER_PASSWORD;

export PROMETHEUS_PASSWORD="prometheus"

# TODO: This is FRaaS specific - we need to figure out what makes sense here
export ORG_UI_URL="https://$FQDN"

# Generated - these can be unique on every boot since AM just checks against itself.
DSAME_PASSWORD=$(cat /dev/urandom | tr -dc 'A-Za-z0-9' | fold -w 36 | head -n 1)
export DSAMEUSER_PASSWORD_HASHED_ENCRYPTED=$(echo $DSAME_PASSWORD | am-crypto hash | am-crypto encrypt des)
export DSAMEUSER_PASSWORD_ENCRYPTED=$(echo $DSAME_PASSWORD | am-crypto encrypt des)
ANON_PASSWORD=$(cat /dev/urandom | tr -dc 'A-Za-z0-9' | fold -w 36 | head -n 1)
export ANONYMOUS_PASSWORD_HASHED_ENCRYPTED=$(echo $ANON_PASSWORD | am-crypto hash | am-crypto encrypt des)
# TODO: Fix AMADMIN_PASSWORD...
export AMADMIN_PASSWORD_HASHED_ENCRYPTED=$(echo $AMADMIN_PASS | am-crypto hash  | am-crypto encrypt des)


AM_TMP=$( echo $AM_AUTHENTICATION_SHARED_SECRET | base64)
export AM_AUTHENTICATION_SHARED_SECRET=$(echo $AM_TMP | am-crypto encrypt des)
export AM_SESSION_STATELESS_SIGNING_KEY=$(echo $AM_SESSION_STATELESS_SIGNING_KEY_CLEAR | am-crypto encrypt des)
export AM_SESSION_STATELESS_ENCRYPTION_KEY=$(echo $AM_SESSION_STATELESS_ENCRYPTION_KEY | am-crypto encrypt des)


# Keystores. Note FRaaS uses a path of /var/run/secrets/openam   - not /am
export DEFAULT_KEYSTORE=/var/run/secrets/am/keystore/keystore-runtime.jceks
export DEFAULT_KEYSTORE_PASSWORD=$(cat /var/run/secrets/am/password/storepassruntime)
export DEFAULT_KEYSTORE_ENTRY_PASSWORD=$(cat /var/run/secrets/am/password/keypassruntime)
export AM_CONFIG_MODE=PROVIDED
export FBC_ENABLED=true

# todo: all the bind passwords are also encrypted...
export USERSTORE_PASSWORD_ENC=$(echo $USERSTORE_PASSWORD | am-crypto encrypt des)
export CFG_USER_PASSWORD_ENC=$(echo $CFG_USER_PASSWORD | am-crypto encrypt des)
export CTS_PASSWORD_ENC=$(echo $CTS_PASSWORD | am-crypto encrypt des)
export POLICY_PASSWORD_ENC=$(echo $POLICY_PASSWORD | am-crypto encrypt des)
unset AM_ENC_KEY

# For debugging purposes
echo "****** Environment *************: "
env | sort

exec /home/forgerock/docker-entrypoint.sh
