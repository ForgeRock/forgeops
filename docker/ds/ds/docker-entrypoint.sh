#!/usr/bin/env bash
#
# Copyright 2019-2021 ForgeRock AS. All Rights Reserved
#
# Use of this code requires a commercial software license with ForgeRock AS.
# or with one of its affiliates. All use shall be exclusively subject
# to such license between the licensee and ForgeRock AS.

set -eu
set -x

# ParallelGC with a single generation tenuring threshold has been shown to give the best
# performance vs determinism trade-off for servers using JVM heaps of less than 8GB,
# as well as all batch tool use-cases such as import-ldif.
# Unusual deployments, such as those requiring very large JVM heaps, should tune this setting
# and use a different garbage collector, such as G1.
# The /dev/urandom device is up to 4 times faster for crypto operations in some VM environments
# where the Linux kernel runs low on entropy. This settting does not negatively impact random number security
# and is recommended as the default.
DEFAULT_OPENDJ_JAVA_ARGS="-XX:MaxRAMPercentage=75 -XX:+UseParallelGC -XX:MaxTenuringThreshold=1 -Djava.security.egd=file:/dev/urandom"
export OPENDJ_JAVA_ARGS=${OPENDJ_JAVA_ARGS:-${DEFAULT_OPENDJ_JAVA_ARGS}}

export DS_GROUP_ID=${DS_GROUP_ID:-default}
export DS_SERVER_ID=${DS_SERVER_ID:-${HOSTNAME:-localhost}}
export DS_ADVERTISED_LISTEN_ADDRESS=${DS_ADVERTISED_LISTEN_ADDRESS:-$(hostname -f)}
export DS_CLUSTER_TOPOLOGY=${DS_CLUSTER_TOPOLOGY:-""}
export MCS_ENABLED=${MCS_ENABLED:-false}

# If the advertised listen address looks like a Kubernetes pod host name of the form
# <statefulset-name>-<ordinal>.<domain-name> then derived the default bootstrap servers names as
# <statefulset-name>-0.<domain-name>,<statefulset-name>-1.<domain-name>.
#
# Sample hostnames from Kubernetes include:
#
#     ds-1.userstore.svc.cluster.local
#     ds-userstore-1.userstore.svc.cluster.local
#     userstore-1.userstore.jnkns-pndj-bld-pr-4958-1.svc.cluster.local
#     ds-userstore-1.userstore.jnkns-pndj-bld-pr-4958-1.svc.cluster.local
#
# Additionally, in multi region deployments, build unique definitions based
# on the regions, which are also part of the pod FQDN.
# For example, givens regions "europe" and "us", european pods will have:
# FQDN:              ds-cts-1.ds-cts-europe.namespace.svc.cluster.local
# And we can compute:
# Server ID:         ds-cts-1_europe
# Group ID:          europe
# Bootstrap servers: ds-cts-0.ds-cts-europe.namespace.svc.cluster.local,ds-cts-0.ds-cts-us.namespace.svc.cluster.local
#
if [[ "${DS_ADVERTISED_LISTEN_ADDRESS}" =~ [^.]+-[0-9]+\..+ ]]; then
    # Domain is everything after the first dot
    podDomain=${DS_ADVERTISED_LISTEN_ADDRESS#*.}
    # Name is everything up to the first dot
    podName=${DS_ADVERTISED_LISTEN_ADDRESS%%.*}
    podPrefix=${podName%-*}

    ds0=${podPrefix}-0.${podDomain}:8989
    if [ -n "${DS_CLUSTER_TOPOLOGY}" ]; then
        # Service name is the first subdomain of the FQDN
        podService=${podDomain%%.*}
        podServicePrefix=${podService%-*}
        newBootstrapServers=${ds0}
        # Configure bootstrap servers to include replication service if MCS is enabled
        if ${MCS_ENABLED}; then
            podDomain=${podDomain/cluster/clusterset}
            newBootstrapServers="${podPrefix}-0.${podService##*-}.${podDomain}:8989"
        fi
        for cluster in ${DS_CLUSTER_TOPOLOGY//,/ }; do
            regionService=${podServicePrefix}-${cluster}
            # If the service name is ours, then set our identifiers
            # else add the first pod of the cluster to the bootstrap servers
            if [ ${regionService} == ${podService} ]; then
               export DS_GROUP_ID=${cluster}
               export DS_SERVER_ID=${podName}_${cluster}
               if ${MCS_ENABLED}; then
                    DS_ADVERTISED_LISTEN_ADDRESS="${podPrefix}-0.${cluster}.${regionService}.${podDomain#*.}"
               fi
            else
                if ${MCS_ENABLED}; then
                    additional="${podPrefix}-0.${cluster}.${regionService}.${podDomain#*.}:8989"
                else
                    additional="${podPrefix}-0.${regionService}.${podDomain#*.}:8989"
                fi
                newBootstrapServers="${newBootstrapServers},${additional}"
            fi
        done
        export DS_BOOTSTRAP_REPLICATION_SERVERS=${DS_BOOTSTRAP_REPLICATION_SERVERS:-${newBootstrapServers}}
    else
        ds1=${podPrefix}-1.${podDomain}:8989
        export DS_BOOTSTRAP_REPLICATION_SERVERS=${DS_BOOTSTRAP_REPLICATION_SERVERS:-${ds0},${ds1}}
    fi
else
    export DS_BOOTSTRAP_REPLICATION_SERVERS=${DS_BOOTSTRAP_REPLICATION_SERVERS:-${DS_ADVERTISED_LISTEN_ADDRESS}:8989}
fi


validateImage() {
    # FIXME: fail-fast if database encryption has been used when the image was built (OPENDJ-6598).
    diff -q template/db/adminRoot/admin-backend.ldif db/adminRoot/admin-backend.ldif > /dev/null || {
        echo "The server cannot start because it appears that database encryption"
        echo "was enabled for a backend when the Docker image was built."
        echo "This feature is not yet supported when using Docker."
        exit 1
    }
}


linkDataDirectories() {
    # List of directories which are expected to be found in the data directory.
    dataDirs="db changelogDb locks var config"

    mkdir -p data
    for d in ${dataDirs}; do
        if [[ ! -d "data/$d" ]]; then
            echo "No data/$d directory present."
            mv $d data
        else
            # the data/$d exists -we want to make sure it is used - not the one in the image
            # rename the docker directory so the link works as it will want to overwrite the $d name
            mv $d $d.docker
        fi
        echo "Linking $d to data/$d"
        ln -s data/$d
    done
}

# If the pod was terminated abnormally then lock file may not have been cleaned up.
removeLocks() {
    rm -f /opt/opendj/locks/server.lock
}

# Make it easier to run tools interactively by exec'ing into the running container.
setOnlineToolProperties() {
    mkdir -p ~/.opendj
    cp config/tools.properties ~/.opendj
}

upgradeDataAndRebuildDegradedIndexes() {

    # Build an array containing the list of pluggable backend base DNs by redirecting the command output to
    # mapfile using process substitution.
    mapfile -t BASE_DNS < <(./bin/ldifsearch -b cn=backends,cn=config -s one data/config/config.ldif "(&(objectclass=ds-cfg-pluggable-backend)(ds-cfg-enabled=true))" ds-cfg-base-dn | grep "^ds-cfg-base-dn" | cut -c17-)

    # Upgrade is idempotent, so it should have no effect if there is nothing to do.
    # Fail-fast if the config needs upgrading because it should have been done when the image was built.
    echo "Upgrading configuration and data..."
     ./upgrade --dataOnly --acceptLicense --force --ignoreErrors --no-prompt

    # Rebuild any corrupt/missing indexes.
    for baseDn in "${BASE_DNS[@]}"; do
        echo "Rebuilding degraded indexes for base DN \"${baseDn}\"..."
        rebuild-index --offline --noPropertiesFile --rebuildDegraded --baseDn "${baseDn}" > /dev/null
    done
}

preExec() {
    echo
    echo "Server configured with:"
    echo "    Group ID                        : $DS_GROUP_ID"
    echo "    Server ID                       : $DS_SERVER_ID"
    echo "    Advertised listen address       : $DS_ADVERTISED_LISTEN_ADDRESS"
    echo "    Bootstrap replication server(s) : $DS_BOOTSTRAP_REPLICATION_SERVERS"
    echo
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

# These should be set and passed in by K8S. We use the same defaults here.
export DS_UID_ADMIN_PASSWORD_FILE="${DS_UID_ADMIN_PASSWORD_FILE:-/var/run/secrets/admin/dirmanager.pw}"
export DS_UID_MONITOR_PASSWORD_FILE="${DS_UID_MONITOR_PASSWORD_FILE:-/var/run/secrets/monitor/monitor.pw}"

setAdminAndMonitorPasswords() {
    adminPassword="${DS_UID_ADMIN_PASSWORD:-$(cat "${DS_UID_ADMIN_PASSWORD_FILE}")}"
    monitorPassword="${DS_UID_MONITOR_PASSWORD:-$(cat "${DS_UID_MONITOR_PASSWORD_FILE}")}"
    setUserPasswordInLdifFile data/db/rootUser/rootUser.ldif       "uid=admin"   $adminPassword
    setUserPasswordInLdifFile data/db/monitorUser/monitorUser.ldif "uid=monitor" $monitorPassword
}


init() {
    echo "initializing..."
    linkDataDirectories
    removeLocks
    upgradeDataAndRebuildDegradedIndexes
}

# Check for a user supplied script $1, and if not found use the default one.
executeScript() {
    # Kubernetes creates a sym link from $1 to ..data/$1 - so we test for the sym link.
    if [[ -L scripts/$1 ]]; then
    echo "Executing user supplied script $1"
        ./scripts/$1
    else
        echo "Executing default script $1"
        ./default-scripts/$1
    fi
}

CMD="${1:-help}"
case "$CMD" in

# init is run in an init container and prepares the directory for running.
init)
    [[ -d data/db ]] && {
        echo "data/ directory contains data. setup skipped";
        # Init still needs to check link the data/ directory and rebuild indexes.
        init
        # Set the admin and monitor passwords from K8S secrets
        setAdminAndMonitorPasswords
        # If the user supplies a post-init script, run it
        # The default-script is a no-op.
        executeScript post-init
        exit 0;
    }
    # Else - no data is present, we need to run setup.
    linkDataDirectories
    executeScript setup
    init
    setAdminAndMonitorPasswords
    ;;

backup)
    [[ ! -d data/db ]] && {
        echo "There is no data to backup!";
        exit 1
    }
    init
    executeScript backup
    ;;

restore)
    init
    executeScript restore
    ;;

# Start the server.
# start-ds falls through the case statement
start-ds)
    ;&
start)
    init
    preExec
    exec start-ds --nodetach
    ;;

dev)
    # Sleep until Kubernetes terminates the pod using a SIGTERM.
    echo "Connect using 'kubectl exec -it POD -- /bin/bash'"
    waitUntilSigTerm
    ;;

*)
    validateImage
    linkDataDirectories
    removeLocks
    preExec
    echo "Undefined entrypoint. Will exec $@"
    shift
    exec "$@"
    ;;

esac
