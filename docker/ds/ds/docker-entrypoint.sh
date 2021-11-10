#!/usr/bin/env bash
#
# The entrypoint script for the fully mutable directory deployment.
# Read this carefully if your not deploying with the provided operator or Kubernetes manifests.
#
# Copyright 2019-2021 ForgeRock AS. All Rights Reserved
#
# Use of this code requires a commercial software license with ForgeRock AS.
# or with one of its affiliates. All use shall be exclusively subject
# to such license between the licensee and ForgeRock AS.

# set -x 


source /opt/opendj/env.sh

# set -eu


# If the pod was terminated abnormally then lock file may not have been cleaned up.
removeLocks() {
    rm -f $DS_DATA_DIR/locks/server.lock
}

# Make it easier to run tools interactively by exec'ing into the running container.
setOnlineToolProperties() {
    mkdir -p ~/.opendj
    cp config/tools.properties ~/.opendj
}

upgradeDataAndRebuildDegradedIndexes() {

    # Build an array containing the list of pluggable backend base DNs by redirecting the command output to
    # mapfile using process substitution.
    mapfile -t BASE_DNS < <(./bin/ldifsearch -b cn=backends,cn=config -s one $DS_DATA_DIR/config/config.ldif "(&(objectclass=ds-cfg-pluggable-backend)(ds-cfg-enabled=true))" ds-cfg-base-dn | grep "^ds-cfg-base-dn" | cut -c17-)

    # Upgrade is idempotent, so it should have no effect if there is nothing to do.
    # Fail-fast if the config needs upgrading because it should have been done when the image was built.
    echo "Upgrading configuration and data..."
     ./upgrade --acceptLicense --force --ignoreErrors --no-prompt

    # Rebuild any corrupt/missing indexes.
    for baseDn in "${BASE_DNS[@]}"; do
        echo "Rebuilding degraded indexes for base DN \"${baseDn}\"..."
        rebuild-index --offline --noPropertiesFile --rebuildDegraded --baseDn "${baseDn}" > /dev/null
    done
}


waitUntilSigTerm() {
    trap 'echo "Caught SIGTERM"' SIGTERM
    while :
    do
       sleep infinity &
       wait $!
    done
}

setUserPasswordInLdifFile() {
    file=$1
    dn=$2
    pwd=$3

    echo "Updating the \"${dn}\" password"

    # Set the JVM args to avoid blowing up the container memory.
    enc_pwd=$(OPENDJ_JAVA_ARGS="-Xmx256m -Djava.security.egd=file:/dev/./urandom" encode-password -s "PBKDF2-HMAC-SHA256" -c "${pwd}")

    ldifmodify "${file}" > "${file}.tmp" << EOF
dn: ${dn}
changetype: modify
replace: userPassword
userPassword: ${enc_pwd}
EOF
    rm "${file}"
    mv "${file}.tmp" "${file}"
}


setAdminAndMonitorPasswords() {
    adminPassword="${DS_UID_ADMIN_PASSWORD:-$(cat "${DS_UID_ADMIN_PASSWORD_FILE}")}"
    monitorPassword="${DS_UID_MONITOR_PASSWORD:-$(cat "${DS_UID_MONITOR_PASSWORD_FILE}")}"
    setUserPasswordInLdifFile $DS_DATA_DIR/db/rootUser/rootUser.ldif       "uid=admin"   $adminPassword
    setUserPasswordInLdifFile $DS_DATA_DIR/db/monitorUser/monitorUser.ldif "uid=monitor" $monitorPassword
}

# Copy the K8S secrets to the writable volume. The secrets are expected to be of type k8s.io/tls.
# These are PEM files -see ds-setup.sh to understand how DS is configured for PEM support.
# These are likely cert-manager generated, but any tool that generates valid PEM and puts it a k8s tls secret can be used.
# See https://bugster.forgerock.org/jira/browse/OPENDJ-8374
copyKeys() {
    mkdir -p $PEM_KEYS_DIRECTORY
    mkdir -p $PEM_TRUSTSTORE_DIRECTORY

    # Copy the SSL certs. We also copy the ssl ca.crt to be used as the trustore in the case that 
    # a seperate truststore is not provided.
    [[ -d $SSL_CERT_DIR ]] && cat $SSL_CERT_DIR/tls.crt $SSL_CERT_DIR/tls.key  >$PEM_KEYS_DIRECTORY/ssl-key-pair && \
        cp $SSL_CERT_DIR/ca.crt $PEM_TRUSTSTORE_DIRECTORY/trust.pem

    [[ -d $MASTER_CERT_DIR ]] && cat $MASTER_CERT_DIR/tls.key $MASTER_CERT_DIR/tls.crt $MASTER_CERT_DIR/ca.crt > $PEM_KEYS_DIRECTORY/master-key

    # If the user provides a truststore then use it...
    [[ -d $TRUSTSTORE_DIR ]] && cp $TRUSTSTORE_DIR/ca.crt $PEM_TRUSTSTORE_DIRECTORY/trust.pem
}

# Execute a user supplied script hook, or use the default if none is supplied.
# Check for a user supplied script $1, and if not found use the default one.
executeScript() {
    # Kubernetes creates a sym link from $1 to ..data/$1 - so we test for the sym link.
    if [[ -L scripts/$1 ]]; then
    echo "Executing user supplied $1 script"
        ./scripts/$1
    else
        echo "Executing default $1 script"
        ./default-scripts/$1
    fi
}


init() {
    # Make sure master keys and truststore are in place and up to date.
    copyKeys
    upgradeDataAndRebuildDegradedIndexes
    # Set the admin and monitor passwords from K8S secrets
    setAdminAndMonitorPasswords
}


CMD="${1:-help}"
case "$CMD" in

# init is run in an init container and prepares the directory for running.
initialize-only)
    ;&
init)
    if [[ -d "$DS_DATA_DIR/db" ]];  then
        echo "data/ directory contains data. setup is not required";
        # Init still needs to check and rebuild indexes.
        init

        # If the user supplies a post-init script, run it
        # The default-script is a no-op.
        executeScript post-init
        exit 0;
    fi
    # Else - no data is present, we need to run setup.
    echo "Untaring protoype setup to $DS_DATA_DIR"
    tar --no-overwrite-dir -C $DS_DATA_DIR -xvzf data.tar.gz
    copyKeys
    executeScript setup
    init
    ;;

backup)
    [[ ! -d $DS_DATA_DIR/db ]] && {
        echo "There is no data to backup!";
        exit 1
    }
    init
    executeScript backup
    ;;

restore)
    # restore needs acces to the master keypair to decrypt data
    copyKeys
    executeScript restore
    ;;

# Start the server.
# start-ds falls through the case statement
start-ds)
    ;&
start)
    removeLocks
    exec start-ds --nodetach
    ;;

dev-init)
    init
    ;&

dev)
    # Sleep until Kubernetes terminates the pod using a SIGTERM.
    echo "Connect using 'kubectl exec -it POD -- /bin/bash'"
    waitUntilSigTerm
    ;;
*)
    removeLocks
    echo "Undefined entrypoint. Will exec $@"
    shift
    exec "$@"
    ;;

esac
