# Source this file to set the environment variables for the Docker container.

# ParallelGC with a single generation tenuring threshold has been shown to give the best
# performance vs determinism trade-off for servers using JVM heaps of less than 8GB,
# as well as all batch tool use-cases such as import-ldif.
# Unusual deployments, such as those requiring very large JVM heaps, should tune this setting
# and use a different garbage collector, such as G1.
# The /dev/urandom device is up to 4 times faster for crypto operations in some VM environments
# where the Linux kernel runs low on entropy. This settting does not negatively impact random number security
# and is recommended as the default.


export DEFAULT_OPENDJ_JAVA_ARGS="-XX:MaxRAMPercentage=75 -XX:+UseParallelGC -XX:MaxTenuringThreshold=1 -Djava.security.egd=file:/dev/urandom"
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
# DS currently supports 3 multi-cluster solutions. The identifiers will be updated as follows assuming cluster names eu and us:
# **CloudDNS for GKE**
# FQDN:              ds-cts-1.ds-cts.<namespace>.svc.eu
# Results in:
# Server ID:         ds-cts-1_eu
# Group ID:          eu
# Bootstrap servers: ds-cts-0.ds-cts.<namespace>.svc.eu,ds-cts-0.ds-cts.<namespace>.svc.us
#
# **KubeDNS**
# FQDN:              ds-cts-1.ds-cts-eu.<namespace>.svc.cluster.local
# Results in:
# Server ID:         ds-cts-1_eu
# Group ID:          eu
# Bootstrap servers: ds-cts-0.ds-cts-eu.<namespace>.svc.cluster.local,ds-cts-0.ds-cts-us.<namespace>.svc.cluster.local
#
# **GKE multi-cluster Services(MCS) **
# FQDN:              ds-cts-1.ds-cts-eu.eu.<namespace>.svc.cluster.local
# Results in:
# Server ID:         ds-cts-1_eu
# Group ID:          eu
# Bootstrap servers: ds-cts-0.ds-cts-eu.eu.<namespace>.svc.cluster.local,ds-cts-0.ds-cts-us.us.<namespace>.svc.cluster.local
#

if [[ "${DS_ADVERTISED_LISTEN_ADDRESS}" =~ [^.]+-[0-9]+\..+ ]]; then
    # Domain is everything after the first dot
    podDomain=${DS_ADVERTISED_LISTEN_ADDRESS#*.}
    # Name is everything up to the first dot
    podName=${DS_ADVERTISED_LISTEN_ADDRESS%%.*}
    podPrefix=${podName%-*}

    ds0=${podPrefix}-0.${podDomain}:8989

    # Multi-cluster configurations
    if [[ -n "${DS_CLUSTER_TOPOLOGY}" ]]; then
        # Service name is the first subdomain of the FQDN
        podService=${podDomain%%.*}
        podServicePrefix=${podService%-*}
        newBootstrapServers=${ds0}
        # If MCS is enabled, configure bootstrap servers to include replication service
        if ${MCS_ENABLED}; then
            podDomain=${podDomain/cluster/clusterset}
            newBootstrapServers="${podPrefix}-0.${podService##*-}.${podDomain}:8989"
        fi
        for cluster in ${DS_CLUSTER_TOPOLOGY//,/ }; do
            ## Google CloudDNS
            if [[ "$podDomain" != *cluster.local ]] && [[ "$podDomain" != *clusterset.local ]]; then
                # set clusterIdentifier to match the CloudDNS domain
                clusterIdentifier=${podDomain##*.}
                # If ${cluster} is our cluster, then set identifiers else add the first pod to the bootstrap servers
                if [[ "${clusterIdentifier}" == "${cluster}" ]]; then
                    export DS_GROUP_ID=$cluster
                    export DS_SERVER_ID=${podName}_${cluster}
                else
                    domain=${podDomain#*.}
                    additional="${podPrefix}-0.${podService}.${domain%.*}.${cluster}:8989"
                    newBootstrapServers="${newBootstrapServers},${additional}"
                fi
            ## MCS (GKE multi-cluster Services)
            elif ${MCS_ENABLED}; then
                # set clusterIdentifier to include service name and cluster
                clusterIdentifier=${podServicePrefix}-${cluster}
                # If ${cluster} is our cluster, then set identifiers else add the first pod to the bootstrap servers
                if [ ${clusterIdentifier} == ${podService} ]; then
                    export DS_GROUP_ID=$cluster
                    export DS_SERVER_ID=${podName}_${cluster}
                    # Add replication service
                    DS_ADVERTISED_LISTEN_ADDRESS="${podPrefix}-0.${cluster}.${regionService}.${podDomain#*.}"
                else
                    additional="${podPrefix}-0.${cluster}.${regionService}.${podDomain#*.}:8989"
                    newBootstrapServers="${newBootstrapServers},${additional}"
                fi
            ## KubeDNS
            else
                # set clusterIdentifier to include service name and cluster
                clusterIdentifier=${podServicePrefix}-${cluster}
                # If ${cluster} is our cluster, then set identifiers else add the first pod to the bootstrap servers
                if [ ${clusterIdentifier} == ${podService} ]; then
                    export DS_GROUP_ID=$cluster
                    export DS_SERVER_ID=${podName}_${cluster}
                else
                    additional="${podPrefix}-0.${regionService}.${podDomain#*.}:8989"
                    newBootstrapServers="${newBootstrapServers},${additional}"
                fi
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

# Set to true in order to use the demo keystore and set the admin and monitor passwords to "password".
export USE_DEMO_KEYSTORE_AND_PASSWORDS=${USE_DEMO_KEYSTORE_AND_PASSWORDS:-false}
if [[ "${USE_DEMO_KEYSTORE_AND_PASSWORDS}" == "true" ]]
then
    echo "WARNING: The container will use the demo keystore, YOUR DATA IS AT RISK"
    echo
fi


# These are the default locations of cert-manager generated PEM files are mounted.
# These files must be copied to appropriate location and format expected by the DS PEM manager
export SSL_CERT_DIR="/var/run/secrets/ds-ssl-keypair"
export MASTER_CERT_DIR="/var/run/secrets/ds-master-keypair"
export TRUSTSTORE_DIR="/var/run/secrets/truststore"


# These should be set and passed in by K8S. We use the same defaults here.
export DS_UID_ADMIN_PASSWORD_FILE="${DS_UID_ADMIN_PASSWORD_FILE:-/var/run/secrets/admin/dirmanager.pw}"
export DS_UID_MONITOR_PASSWORD_FILE="${DS_UID_MONITOR_PASSWORD_FILE:-/var/run/secrets/monitor/monitor.pw}"


echo
echo "Server configured with:"
echo "    Group ID                        : $DS_GROUP_ID"
echo "    Server ID                       : $DS_SERVER_ID"
echo "    Advertised listen address       : $DS_ADVERTISED_LISTEN_ADDRESS"
echo "    Bootstrap replication server(s) : $DS_BOOTSTRAP_REPLICATION_SERVERS"
echo
