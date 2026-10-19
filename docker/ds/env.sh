# Source this file to set the environment variables for the Docker container.
#
# Customizing: every setting below is read as ${VAR:-default}, so set the
# corresponding environment variable to override it. In a chart deployment,
# set DS_* variables through the ds_idrepo.env / ds_cts.env / platform.env
# chart values (or envFrom secrets); in a standalone image run, set them in
# the container environment (or bake them into the image). Note the chart
# mounts THIS file over the image's baked copy — customize through the
# environment, not by editing the image's env.sh.
#
# Two modes are supported via IMAGE_MODE (default "forgeops"):
#   forgeops  - forgeops deployment contract: password files under
#               /var/run/secrets/opendj-passwords/ (opt-in setting, on by
#               default), SSL/MASTER/TRUSTSTORE cert directories matching
#               the PEM managers created by ds-setup.sh, server id suffixed
#               with the group id. This is the contract the forgeops images
#               have always shipped; bare-image runs (kustomize manifests,
#               plain docker run) get it when IMAGE_MODE is unset.
#   base      - upstream samples/docker contract: keystore-based runtime,
#               admin/monitor password files under secrets/, bootstrap
#               replication servers derived from the pod hostname for both
#               replicas (ds0, ds1). Opt-in via IMAGE_MODE=base.
# Both branches share the G1 GC defaults with the DS_JAVA_ARGS tunables
# (DS_JAVA_GC_LOGFILE, DS_JAVA_GC_PAUSE_TARGET, DS_JAVA_INITIAL_RAM_PERCENTAGE,
# DS_JAVA_MAX_RAM_PERCENTAGE).
#
# busybox ash notes (alpine): no bash-only features are used here; the
# k8s-pod-hostname regex is evaluated with grep -E instead of [[ =~ ]].

# DS_JAVA_ARGS is the primary env var for DS 8.x+. OPENDJ_JAVA_ARGS is
# deprecated but still exported for DS 7.4/7.5 backward compatibility.
DEFAULT_DS_JAVA_ARGS="
-XX:+UseG1GC
-XX:+ExitOnOutOfMemoryError
-Djava.security.egd=file:/dev/urandom
-Xlog:gc:${DS_JAVA_GC_LOGFILE:-/opt/opendj/data/gc.log}:time,uptime:filecount=${DS_JAVA_GC_FILE_COUNT:-5},filesize=${DS_JAVA_GC_FILE_SIZE:-50M}
-XX:MaxGCPauseMillis=${DS_JAVA_GC_PAUSE_TARGET:-300}
-XX:InitialRAMPercentage=${DS_JAVA_INITIAL_RAM_PERCENTAGE:-65}
-XX:MaxRAMPercentage=${DS_JAVA_MAX_RAM_PERCENTAGE:-65}
-XX:MaxTenuringThreshold=${DS_JAVA_MAX_TENURING_THRESHOLD:-1}
${DS_JAVA_ADDITIONAL_ARGS:-}
"
export DS_JAVA_ARGS=${DS_JAVA_ARGS:-${DEFAULT_DS_JAVA_ARGS}}
export OPENDJ_JAVA_ARGS=${DS_JAVA_ARGS}

MODE=${IMAGE_MODE:-forgeops}

# By default the admin and monitor passwords are provided as plain-text.
# Set this to true if the passwords have been pre-encoded externally.
export DS_USE_PRE_ENCODED_PASSWORDS=${DS_USE_PRE_ENCODED_PASSWORDS:-false}

if [ "$MODE" = "forgeops" ]; then
    # forgeops deployments provision passwords via k8s secrets at these paths
    # and expect them to be set unconditionally at startup (upstream forgeops
    # env.sh defaults).
    export DS_SET_UID_ADMIN_AND_MONITOR_PASSWORDS=${DS_SET_UID_ADMIN_AND_MONITOR_PASSWORDS:-true}
    export DS_UID_ADMIN_PASSWORD_FILE="${DS_UID_ADMIN_PASSWORD_FILE:-/var/run/secrets/opendj-passwords/dirmanager.pw}"
    export DS_UID_MONITOR_PASSWORD_FILE="${DS_UID_MONITOR_PASSWORD_FILE:-/var/run/secrets/opendj-passwords/monitor.pw}"
else
    # base mode (upstream samples/docker contract, IMAGE_MODE=base): password
    # setting is opt-in, defaults are relative to the instance secrets/
    # directory.
    export DS_SET_UID_ADMIN_AND_MONITOR_PASSWORDS=${DS_SET_UID_ADMIN_AND_MONITOR_PASSWORDS:-false}
    export DS_UID_ADMIN_PASSWORD_FILE=${DS_UID_ADMIN_PASSWORD_FILE:-secrets/admin.pwd}
    export DS_UID_MONITOR_PASSWORD_FILE=${DS_UID_MONITOR_PASSWORD_FILE:-secrets/monitor.pwd}
fi

# Group Id is important in multi-cluster (multi-region) deployments to
# localize replication. For single cluster deployment, using default is fine.
export DS_GROUP_ID=${DS_GROUP_ID:-default}
# Concat the hostname and group id to make a unique server id. For example
# if ds-idrep-0 is deployed both in groupid=us-west and group-id=us-east, this
# serves to differentiate the two servers.
HID="$(hostname)-$DS_GROUP_ID"
export DS_SERVER_ID=${DS_SERVER_ID:-${HID}}
# By default we advertise to listen on the default hostname.
export DS_ADVERTISED_LISTEN_ADDRESS=${DS_ADVERTISED_LISTEN_ADDRESS:-$(hostname -f)}

# If the advertised listen address looks like a Kubernetes pod host name of
# the form <statefulset-name>-<ordinal>.<domain-name> then derive the default
# bootstrap servers names as
# <statefulset-name>-0.<domain-name>,<statefulset-name>-1.<domain-name>.
#
# Sample hostnames from Kubernetes include:
#
#     ds-1.userstore.svc.cluster.local
#     ds-userstore-1.userstore.svc.cluster.local
#     userstore-1.userstore.jnkns-pndj-bld-pr-4958-1.svc.cluster.local
#     ds-userstore-1.userstore.jnkns-pndj-bld-pr-4958-1.svc.cluster.local
#
# To deploy in a multi-cluster scenario explicitly set the
# DS_BOOTSTRAP_REPLICATION_SERVERS per your topology. Examples below:
# **Cloud DNS for GKE**
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
# **GKE multi-cluster Services (MCS)**
# FQDN:              ds-cts-1.ds-cts-eu.eu.<namespace>.svc.cluster.local
# Results in:
# Server ID:         ds-cts-1_eu
# Group ID:          eu
# Bootstrap servers: ds-cts-0.ds-cts-eu.eu.<namespace>.svc.cluster.local,ds-cts-0.ds-cts-us.us.<namespace>.svc.cluster.local

# busybox ash has no =~ regex; use grep -qE for the pod-hostname test.
if printf '%s' "$DS_ADVERTISED_LISTEN_ADDRESS" | grep -qE '[^.]+-[0-9]+\..+'; then
    # Domain is everything after the first dot
    podDomain=${DS_ADVERTISED_LISTEN_ADDRESS#*.}
    # Name is everything up to the first dot
    podName=${DS_ADVERTISED_LISTEN_ADDRESS%%.*}
    podPrefix=${podName%-*}

    ds0=${podPrefix}-0.${podDomain}:8989
    ds1=${podPrefix}-1.${podDomain}:8989
    # Set the default bootstrap servers unless the user explicitly provides it
    export DS_BOOTSTRAP_REPLICATION_SERVERS=${DS_BOOTSTRAP_REPLICATION_SERVERS:-${ds0},${ds1}}
else
    export DS_BOOTSTRAP_REPLICATION_SERVERS=${DS_BOOTSTRAP_REPLICATION_SERVERS:-${DS_ADVERTISED_LISTEN_ADDRESS}:8989}
fi

if [ "$MODE" = "forgeops" ]; then
    # These are the default locations where cert-manager-generated PEM files
    # are mounted. These files must be copied to the appropriate location and
    # format expected by the DS PEM manager. To change these locations you
    # must also change the ds-setup.sh script.
    export SSL_CERT_DIR="${SSL_CERT_DIR:-/var/run/secrets/ds-ssl-keypair}"
    export MASTER_CERT_DIR="${MASTER_CERT_DIR:-/var/run/secrets/ds-master-keypair}"
    export TRUSTSTORE_DIR="${TRUSTSTORE_DIR:-/var/run/secrets/truststore}"
else
    # base mode (IMAGE_MODE=base): upstream keystore contract - the keystore
    # and PIN are provided at runtime in the secrets directory (mounted or
    # copied there by the entrypoint).
    export SSL_CERT_DIR="${SSL_CERT_DIR:-/opt/opendj/secrets}"
fi

echo
echo "Server configured with:"
echo "    Group ID                        : $DS_GROUP_ID"
echo "    Server ID                       : $DS_SERVER_ID"
echo "    Advertised listen address       : $DS_ADVERTISED_LISTEN_ADDRESS"
echo "    Bootstrap replication server(s) : $DS_BOOTSTRAP_REPLICATION_SERVERS"
echo
