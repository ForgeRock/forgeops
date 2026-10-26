#!/bin/sh
#
# The entrypoint script for the fully mutable directory deployment.
# Read this carefully if you're not deploying with the provided operator or
# Kubernetes manifests.
#
# Two runtime modes are supported via IMAGE_MODE (default "base"), selectable
# purely at run time, e.g.:
#
#     docker run -e IMAGE_MODE=forgeops ...
#
# (Single-image build: both modes run against the SAME baked instance, which
# is always in the forgeops layout - the instance root is the directory named
# by /opt/opendj/data/instance.loc (= $DS_DATA_DIR), so everything
# persistable lives under the PVC mount point and data.tar.gz can prime a
# fresh PVC. The base-mode helpers below resolve the instance root the same
# way, so a base-mode standalone run works on the identical skeleton.)
#
#   base      - upstream samples/docker contract:
#               * start-ds       bootstrap data from the image, link the
#                                runtime keystore from secrets/, upgrade,
#                                rebuild untrusted indexes, optionally set
#                                admin/monitor passwords, start the server.
#               * initialize-only, dev, help - as upstream.
#               * keystore REQUIRED in /opt/opendj/secrets (or
#                 USE_DEMO_KEYSTORE_AND_PASSWORDS=true).
#
#   forgeops   - ForgeOps k8s contract:
#               * init / initialize-only: prime the PVC from data.tar.gz,
#                 copy PEM keys from cert-manager secrets, run the per-pod
#                 runtime-scripts setup/post-init/add-schema hooks, upgrade,
#                 rebuild degraded indexes, set admin/monitor passwords from
#                 k8s password files.
#               * backup/restore/dev-init/set-passwords-only: as before.
#
# The contents of this file are subject to the terms of the Common Development and
# Distribution License (the License). You may not use this file except in compliance with the
# License.
#
# You can obtain a copy of the License at legal/CDDLv1.0.txt. See the License for the
# specific language governing permission and limitations under the License.
#
# When distributing Covered Software, include this CDDL Header Notice in each file and include
# the License file at legal/CDDLv1.0.txt. If applicable, add the following below the CDDL
# Header, with the fields enclosed by brackets [] replaced by your own identifying
# information: "Portions Copyright [year] [name of copyright owner]".
#
# Copyright 2019-2025 Ping Identity Corporation.
#
set -eu
set -o pipefail
# SHELLOPTS is a bash-only variable; busybox ash needs no equivalent.
cd /opt/opendj

# Container environment (JVM args, password-file locations, cert dirs,
# bootstrap replication servers). Mode-aware: see env.sh. The forgeops
# k8s deployment may override any of these via container env/envFrom.
# "source" is supported by busybox ash as well as bash.
. ./env.sh

MODE=${IMAGE_MODE:-base}
case "$MODE" in
    base|forgeops) ;;
    *) echo "docker-entrypoint.sh: unknown IMAGE_MODE '$MODE' (expected base or forgeops)" >&2; exit 1 ;;
esac

# Instance root resolution (single-image contract): the baked skeleton always
# carries an instance.loc (setup --instancePath) pointing at $DS_DATA_DIR
# (the forgeops layout). The base-mode helpers below use this instead of
# assuming the install root, so both runtime modes operate on the identical
# baked instance.
INSTANCE_ROOT="/opt/opendj"
if [ -f /opt/opendj/instance.loc ]; then
    INSTANCE_ROOT=$(cat /opt/opendj/instance.loc)
fi

# ---------- logging (text or JSON via LOG_FORMAT=json) ----------
# busybox ash-compatible replacement for the upstream logger.sh: no bash
# regex, no mapfile, no /bin/date millisecond formats (busybox date has no
# %N), no TTY /proc redirection dependency.
log() {
    log_level=${1:-INFO}
    log_message=${2:-}

    if [ -z "$log_message" ]; then
        if [ "${LOG_FORMAT:-text}" = "json" ]; then
            return
        else
            echo
            return
        fi
    fi

    timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    if [ "${LOG_FORMAT:-text}" = "json" ]; then
        # Sanitize the log message for double quotes and backslashes
        log_message=$(printf '%s' "$log_message" | sed 's/\\/\\\\/g; s/"/\\"/g')
        log_output="{\"eventName\":\"DS-ENTRYPOINT\",\"timestamp\":\"${timestamp}\",\"severity\":\"${log_level}\",\"message\":\"${log_message}\"}"
    else
        log_output="${timestamp} ${log_level} - ${log_message}"
    fi

    case "$log_level" in
        INFO|WARNING|DEBUG) echo "$log_output" ;;
        *)                  echo "$log_output" >&2 ;;
    esac
}
log_warning() { log_input WARNING "$@"; }
log_info()    { log_input INFO "$@"; }
log_error()   { log_input ERROR "$@"; }
log_debug() {
    if [ "${DEBUG_LOGGING:-false}" = "true" ]; then
        log_input DEBUG "$@"
    fi
}
log_new_line() { log INFO ""; }

# Handle both arguments and piped input, mirroring upstream logger.sh's
# log_input: "./upgrade ... | log_info" streams each piped line through the
# logger. busybox ash has no [[ -p ]] test, so the FIFO check is done with
# a POSIX "test -p" instead.
log_input() {
    log_input_level=$1
    shift

    if [ -p /dev/stdin ]; then
        while IFS= read -r line; do
            log "$log_input_level" "$line"
        done
    else
        log "$log_input_level" "$@"
    fi
}

# ---------- shared helpers ----------

# If the pod was terminated abnormally then lock file may not have been cleaned up.
remove_locks() {
    rm -f /opt/opendj/locks/server.lock
}

# Make it easier to run tools interactively by exec'ing into the running container.
set_online_tool_properties() {
    mkdir -p ~/.opendj
    # Optional file: base mode strips the template tools.properties and setup
    # does not always generate one in the instance. Guarded with an "if" (not
    # "&&") so a missing file does not make the function return non-zero and
    # trip "set -e".
    if [ -f "$INSTANCE_ROOT/config/tools.properties" ]; then
        cp "$INSTANCE_ROOT/config/tools.properties" ~/.opendj
    fi
}

wait_until_sig_term() {
    trap 'echo "Caught SIGTERM"' SIGTERM
    while :
    do
       sleep infinity &
       wait $!
    done
}

# ---------- opendj-mode helpers (upstream contract) ----------

# Directories which are expected to be found in the data directory.
OPENDJ_BOOTSTRAP_DATA_SOURCE="db changelogDb import-tmp locks var"

validate_image() {
    # FIXME: fail-fast if database encryption has been used when the image was built (OPENDJ-6598).
    diff -q template/db/adminRoot/admin-backend.ldif "$INSTANCE_ROOT/db/adminRoot/admin-backend.ldif" > /dev/null || {
        log_error "The server cannot start because it appears that database encryption was enabled for a backend when the image was built. This feature is not yet supported when using Docker."
        exit 1
    }
}

# Initialize persisted data in the "data" directory if it is empty, using
# data from the data directories contained in the Docker image.
# NOTE (single-image contract): with the baked instance.loc layout the
# instance root IS /opt/opendj/data and its db/ etc. come fully populated
# from the image, so there is nothing to bootstrap - return immediately.
# The historical move-into-data dance only applies to an in-place,
# instance.loc-less instance (should one ever exist again).
bootstrap_data_from_image_if_needed() {
    if [ -f /opt/opendj/instance.loc ]; then
        return 0
    fi
    cd "$INSTANCE_ROOT"
    for d in ${OPENDJ_BOOTSTRAP_DATA_SOURCE}; do
        if [ -z "$(ls -A "data/$d" 2>/dev/null)" ]; then
            log_warning "Initializing \"data/$d\" from Docker image"
            mkdir -p data
            mv "$d" data
        fi
    done
    cd /opt/opendj
}

link_keystore_and_data_directories() {
    cd "$INSTANCE_ROOT"
    # Ensure that the keystore from the Docker build is no longer being used.
    rm -f config/keystore config/keystore.pin
    if [ "${USE_DEMO_KEYSTORE_AND_PASSWORDS:-false}" = "true" ]; then
      # The baked skeleton uses the PEM managers (config.ldif references the
      # PEM directories, not a file keystore), so the demo keystore only
      # needs to exist where a base-mode runtime expects the secrets dir:
      # under the instance root. The baked PEM managers point at
      # /var/run/secrets/keys|truststore; with no PEM material provided the
      # server still starts (TLS handlers simply have no certs until the
      # deployer supplies them).
      mkdir -p secrets
      cp /opt/opendj/samples/secrets/keystore /opt/opendj/samples/secrets/keystore.pin secrets/
      # The demo keystore embeds the ca-cert trusted entry, so it doubles as
      # the truststore when the deployer provides no separate one (the
      # File Based Trust Manager re-pointed in use_file_keystore_crypto
      # reads config/truststore).
      [ -f secrets/truststore ] || cp secrets/keystore secrets/truststore
    fi
    # Keystore symlink targets are computed per secrets SOURCE, both spelled
    # relative to $INSTANCE_ROOT/config (where the links are READ from):
    #
    #   demo branch above: secrets/ lives INSIDE the instance root
    #   ($INSTANCE_ROOT/secrets) -> from config/ it is always `../secrets`,
    #   whatever the layout.
    #
    #   mounted secrets (the documented contract,
    #   docker-entrypoint-help.md "Volumes and secrets": keystore in
    #   /opt/opendj/secrets): that path is relative to the INSTALL root, so
    #   the spelling depends on the layout --
    #     in-place (INSTANCE_ROOT=/opt/opendj):        ../secrets
    #     instance.loc (= /opt/opendj/data):           ../../secrets
    #   The old hardcoded `../secrets/...` was the in-place spelling; under
    #   the baked instance.loc layout every link dangled (resolving to
    #   /opt/opendj/data/secrets), so a deployer mounting the documented
    #   /opt/opendj/secrets got a container whose base-mode crypto repair
    #   failed on `cat config/keystore.pin`. Found by the pyforge docker
    #   smoke tests (2026-10-08).
    # Links stay relative, so the instance remains relocatable (absolute
    # links into the install root break offline tools).
    if [ "$INSTANCE_ROOT" = "/opt/opendj" ]; then
        secrets_rel="../secrets"
    else
        # instance.loc: INSTANCE_ROOT=/opt/opendj/<tail>; from
        # $INSTANCE_ROOT/config the install root's secrets/ is ../../secrets.
        secrets_rel="../../secrets"
    fi
    if [ "${USE_DEMO_KEYSTORE_AND_PASSWORDS:-false}" = "true" ]; then
        # demo secrets are instance-local (see branch above): always one level up.
        secrets_rel="../secrets"
    fi
    ln -sf "$secrets_rel/keystore" "$secrets_rel/keystore.pin" config/
    # The truststore PROBE must name the secrets SOURCE's directory: this
    # test runs with cwd = $INSTANCE_ROOT, so its spelling is NOT the
    # links' spelling (the links are read from config/, one level deeper).
    #   demo secrets: $INSTANCE_ROOT/secrets (created by the demo branch).
    #   mounted secrets: the documented /opt/opendj/secrets mount --
    #     in-place it is INSTANCE_ROOT-secrets ("secrets"); under
    #     instance.loc it is INSTALL_ROOT-secrets ("../secrets" from
    #     /opt/opendj/data). The old instance-local `secrets/truststore`
    #     probe saw the mount only in the in-place layout; under
    #     instance.loc it looked at $INSTANCE_ROOT/secrets (which no
    #     deployer can produce with the documented mount) and never linked
    #     the truststore -> base-mode boot died on the Administration
    #     Connector SSL init (trust manager's config/truststore missing).
    if [ "${USE_DEMO_KEYSTORE_AND_PASSWORDS:-false}" = "true" ]; then
        secrets_probe="$INSTANCE_ROOT/secrets"
    elif [ "$INSTANCE_ROOT" = "/opt/opendj" ]; then
        secrets_probe="secrets"
    else
        secrets_probe="../secrets"
    fi
    if [ -f "$secrets_probe/truststore" ]; then
        ln -sf "$secrets_rel/truststore" config/
    fi

    for d in ${OPENDJ_BOOTSTRAP_DATA_SOURCE}; do
        # With instance.loc -> the data dir the db/ etc. subtrees ARE the
        # instance's real directories; only ensure they exist (no move/symlink
        # dance - that only applies to an in-place instance layout).
        if [ "$INSTANCE_ROOT" = "/opt/opendj/data" ] || [ -e "$INSTANCE_ROOT/$d" ]; then
            mkdir -p "$INSTANCE_ROOT/$d"
        else
            rm -rf "$d"
            mkdir -p "data/$d"
            ln -s "data/$d" .
        fi
    done
    cd /opt/opendj
}

# Base-mode crypto repair: the single-image skeleton configures the PEM
# Trust/Key managers (the forgeops platform extension) and points the Crypto
# Manager at the PEM Key Manager. A base-mode runtime has no PEM material -
# its keystore is the file-based one in secrets/ (runtime-provided or the
# demo store). Re-point the PEM providers at the instance's PKCS12 file
# store so offline tools (encode-password, import-ldif, upgrade) can use
# crypto services. Idempotent: guarded by whether the PEM manager exists.
use_file_keystore_crypto() {
    # Proceed if EITHER the baked PEM managers are present (fresh config,
    # nothing re-pointed yet) or the file-based managers already exist
    # (post-first-start config: the re-point is applied, the batch below
    # must UPDATE it, not create). Keying on "PEM Key Manager" alone would
    # re-run on every restart and crash-loop on "already an existing one
    # with the same name" (observed live, 2026-09-29: a systemd restart
    # consumer never got past the second start). Keying on "File Based Key
    # Manager" alone would skip FRESH configs entirely (also observed in
    # branch tests: no create on first start). Both set-* (existing) and
    # create (absent) lines make the batch valid under either state, so
    # the whole function is idempotent.
    if ! grep -q "PEM Key Manager" "$INSTANCE_ROOT/config/config.ldif" 2>/dev/null && \
       ! grep -q "File Based Key Manager" "$INSTANCE_ROOT/config/config.ldif" 2>/dev/null; then
        return 0
    fi
    log_info "Base mode: switching key/trust managers from PEM providers to the file-based keystore"
    cd "$INSTANCE_ROOT"
    KS_PIN=$(cat config/keystore.pin)
    KEY_MGR_EXISTS=$(grep -c "cn=File Based Key Manager,cn=Key Manager Providers,cn=config" config/config.ldif || true)
    TRUST_MGR_EXISTS=$(grep -c "cn=File Based Trust Manager,cn=Trust Manager Providers,cn=config" config/config.ldif || true)
    cd /opt/opendj
    dsconfig --offline --no-prompt --batch <<EOM
$( [ "$KEY_MGR_EXISTS" -gt 0 ] && echo "set-key-manager-provider-prop --provider-name \"File Based Key Manager\" --set enabled:true --set \"key-store-file:config/keystore\" --set \"key-store-pin:${KS_PIN}\"" || echo "create-key-manager-provider --provider-name \"File Based Key Manager\" --type file-based --set enabled:true --set \"key-store-file:config/keystore\" --set \"key-store-pin:${KS_PIN}\"" )
$( [ "$TRUST_MGR_EXISTS" -gt 0 ] && echo "set-trust-manager-provider-prop --provider-name \"File Based Trust Manager\" --set enabled:true --set \"trust-store-file:config/truststore\" --set \"trust-store-pin:${KS_PIN}\"" || echo "create-trust-manager-provider --provider-name \"File Based Trust Manager\" --type file-based --set enabled:true --set \"trust-store-file:config/truststore\" --set \"trust-store-pin:${KS_PIN}\"" )
set-crypto-manager-prop --set key-manager-provider:"File Based Key Manager"
set-connection-handler-prop --handler-name https --set key-manager-provider:"File Based Key Manager" --set trust-manager-provider:"File Based Trust Manager"
set-connection-handler-prop --handler-name ldap --set key-manager-provider:"File Based Key Manager" --set trust-manager-provider:"File Based Trust Manager"
set-connection-handler-prop --handler-name ldaps --set key-manager-provider:"File Based Key Manager" --set trust-manager-provider:"File Based Trust Manager"
set-synchronization-provider-prop --provider-name "Multimaster Synchronization" --set key-manager-provider:"File Based Key Manager" --set trust-manager-provider:"File Based Trust Manager"
set-administration-connector-prop --set key-manager-provider:"File Based Key Manager" --set trust-manager-provider:"File Based Trust Manager"
EOM
}

# busybox ash has no bash arrays / mapfile; capture the base DNs in a
# newline-joined variable and iterate with a while-read. Computed lazily
# via set_base_dns rather than at top level: the instance config does not
# exist yet when the entrypoint starts (base mode reads config/config.ldif;
# forgeops mode reads $DS_DATA_DIR/config/config.ldif and only after the
# PVC has been primed from data.tar.gz). The "|| true" guards against
# "set -euo pipefail" killing the script when grep matches nothing.
set_base_dns() {
    BASE_DNS=$(./bin/ldifsearch -b cn=backends,cn=config -s one "$1" "(&(objectclass=ds-cfg-pluggable-backend)(ds-cfg-enabled=true))" ds-cfg-base-dn | grep "^ds-cfg-base-dn" | cut -c17- || true)
}

upgrade_data_and_rebuild_untrusted_indexes() {
    set_base_dns "$INSTANCE_ROOT/config/config.ldif"
    # Upgrade is idempotent, so it should have no effect if there is nothing
    # to do. Fail-fast if the config needs upgrading because it should have
    # been done when the image was built.
    log_info "Upgrading configuration and data..."
    ./upgrade --dataOnly --acceptLicense --force --ignoreErrors --no-prompt --onlySetUntrusted 2>&1 | log_info || log_error "Upgrade failed"

    # Rebuild any untrusted indexes.
    printf '%s\n' "$BASE_DNS" | while IFS= read -r base_dn; do
        [ -z "$base_dn" ] && continue
        log_info "Rebuilding untrusted indexes for base DN \"${base_dn}\"..."
        rebuild-index --offline --noPropertiesFile --rebuildUntrusted --baseDn "${base_dn}" 2>&1 | log_debug
    done
}

set_user_password_in_ldif_file() {
    ldif_file=$1
    dn=$2
    pwd=$3

    if [ ! -s "$ldif_file" ]; then
        log_warning "set_user_password_in_ldif_file: Source ldif to modify [${ldif_file}] is empty or missing... "
        if [ -s "${ldif_file}.bak" ]; then
            cp "${ldif_file}.bak" "${ldif_file}"
            log_warning "set_user_password_in_ldif_file: Restored from ${ldif_file}.bak"
        elif [ -s "${ldif_file}.old" ]; then
            cp "${ldif_file}.old" "${ldif_file}"
            log_warning "set_user_password_in_ldif_file: Restored from ${ldif_file}.old"
        else
            log_error "set_user_password_in_ldif_file: Could not locate a backup ldif file!"
            exit 1
        fi
    fi

    log_info "set_user_password_in_ldif_file: Updating the \"${dn}\" password"

    if [ "${DS_USE_PRE_ENCODED_PASSWORDS:-false}" = "true" ]; then
        enc_pwd="${pwd}"
    else
        # Set the JVM args to avoid blowing up the container memory.
        enc_pwd=$(DS_JAVA_ARGS="-Xmx256m -Djava.security.egd=file:/dev/urandom" encode-password -s "PBKDF2-HMAC-SHA256" -c "${pwd}")
    fi

    ldifmodify --outputLdif "${ldif_file}.tmp" "${ldif_file}" << EOF
dn: ${dn}
changetype: modify
replace: userPassword
userPassword: ${enc_pwd}
EOF
    if [ ! -s "${ldif_file}.tmp" ]; then
        log_warning "set_user_password_in_ldif_file: REFUSING to update ${ldif_file} because ${ldif_file}.tmp was empty"
    else
        mv "${ldif_file}.tmp" "${ldif_file}"
    fi
}

set_admin_and_monitor_passwords_if_needed() {
    if [ "${DS_SET_UID_ADMIN_AND_MONITOR_PASSWORDS:-false}" = "true" ] || [ "${USE_DEMO_KEYSTORE_AND_PASSWORDS:-false}" = "true" ]; then
        if [ "${USE_DEMO_KEYSTORE_AND_PASSWORDS:-false}" = "true" ]; then
          admin_password="password"
          monitor_password="password"
        else
          admin_password="${DS_UID_ADMIN_PASSWORD:-$(cat "${DS_UID_ADMIN_PASSWORD_FILE}")}"
          monitor_password="${DS_UID_MONITOR_PASSWORD:-$(cat "${DS_UID_MONITOR_PASSWORD_FILE}")}"
        fi
        set_user_password_in_ldif_file "$INSTANCE_ROOT/db/rootUser/rootUser.ldif"       "uid=admin"   "$admin_password"
        set_user_password_in_ldif_file "$INSTANCE_ROOT/db/monitorUser/monitorUser.ldif" "uid=monitor" "$monitor_password"
    fi
}

log_server_configuration() {
    log_new_line
    log_info "Server configured with:"
    log_info "    Group ID                        : $DS_GROUP_ID"
    log_info "    Server ID                       : $DS_SERVER_ID"
    log_info "    Advertised listen address       : $DS_ADVERTISED_LISTEN_ADDRESS"
    log_info "    Bootstrap replication server(s) : $DS_BOOTSTRAP_REPLICATION_SERVERS"
    log_new_line
}

# ---------- forgeops-mode helpers (k8s contract) ----------

# Copy the K8S secrets to the writable volume. The secrets are expected to be
# of type k8s.io/tls. These are PEM files - see ds-setup.sh to understand how
# DS is configured for PEM support (forgeops mode).
copyKeys() {
    mkdir -p "$PEM_KEYS_DIRECTORY"
    mkdir -p "$PEM_TRUSTSTORE_DIRECTORY"

    # Copy the SSL certs. We also copy the ssl ca.crt to be used as the
    # truststore in the case that a separate truststore is not provided.
    if [ -d "$SSL_CERT_DIR" ]; then
        cat "$SSL_CERT_DIR/tls.crt" "$SSL_CERT_DIR/tls.key" > "$PEM_KEYS_DIRECTORY/ssl-key-pair" \
            && cp "$SSL_CERT_DIR/ca.crt" "$PEM_TRUSTSTORE_DIRECTORY/trust.pem"
    fi

    if [ -d "$MASTER_CERT_DIR" ]; then
        cat "$MASTER_CERT_DIR/tls.key" "$MASTER_CERT_DIR/tls.crt" "$MASTER_CERT_DIR/ca.crt" > "$PEM_KEYS_DIRECTORY/master-key"
    fi

    # If the user provides a truststore then use it.
    if [ -d "$TRUSTSTORE_DIR" ]; then
        cp "$TRUSTSTORE_DIR/ca.crt" "$PEM_TRUSTSTORE_DIRECTORY/trust.pem"
    fi
}

# busybox ash has no bash arrays; iterate the base DNs via while-read.
upgradeDataAndRebuildDegradedIndexes() {
    set_base_dns "$DS_DATA_DIR/config/config.ldif"
    # Upgrade is idempotent, so it should have no effect if there is nothing to do.
    # Fail-fast if the config needs upgrading because it should have been done when the image was built.
    log_info "Upgrading configuration and data..."
    ./upgrade --acceptLicense --force --ignoreErrors --no-prompt 2>&1 | log_info || log_error "Upgrade failed"

    # Rebuild any corrupt/missing indexes.
    printf '%s\n' "$BASE_DNS" | while IFS= read -r baseDn; do
        [ -z "$baseDn" ] && continue
        log_info "Rebuilding degraded indexes for base DN \"${baseDn}\"..."
        rebuild-index --offline --noPropertiesFile --rebuildDegraded --baseDn "${baseDn}" 2>&1 | log_debug
    done
}

enableMultiplePasswordValues() {
    dsconfig --offline --no-prompt --batch <<EOM
set-password-policy-prop --policy-name "Default Password Policy" --set allow-multiple-password-values:true
set-password-policy-prop --policy-name "Root Password Policy" --set allow-multiple-password-values:true
EOM
}

setUserPasswordInLdifFile() {
    file=$1
    dn=$2
    pwds="$3"

    log_info "Updating the \"${dn}\" password"

    pwd_str=""
    for pw in $pwds ; do
        # Set the JVM args to avoid blowing up the container memory.
        jvm_args="-Xmx256m -Djava.security.egd=file:/dev/urandom"
        enc_pwd=$(DS_JAVA_ARGS="$jvm_args" OPENDJ_JAVA_ARGS="$jvm_args" encode-password -s "PBKDF2-HMAC-SHA256" -c "${pw}")
        if [ "$pwd_str" = "" ] ; then
            pwd_str="userPassword: ${enc_pwd}"
        else
            pwd_str=$(printf '%s\nuserPassword: %s\n' "${pwd_str}" "${enc_pwd}")
        fi
    done

    ldifmodify "${file}" > "${file}.tmp" << EOF
dn: ${dn}
changetype: modify
replace: userPassword
${pwd_str}
EOF
    rm "${file}"
    mv "${file}.tmp" "${file}"
}

setAdminAndMonitorPasswords() {
    adminPassword="${DS_UID_ADMIN_PASSWORD:-$(cat "${DS_UID_ADMIN_PASSWORD_FILE}")}"
    monitorPassword="${DS_UID_MONITOR_PASSWORD:-$(cat "${DS_UID_MONITOR_PASSWORD_FILE}")}"
    if [ -n "${OLD_DIRMANAGER_PW:-}" ] ; then
        adminPassword="$adminPassword $OLD_DIRMANAGER_PW"
    fi
    if [ -n "${OLD_MONITOR_PW:-}" ] ; then
        monitorPassword="$monitorPassword $OLD_MONITOR_PW"
    fi
    enableMultiplePasswordValues
    setUserPasswordInLdifFile "$DS_DATA_DIR/db/rootUser/rootUser.ldif"        "uid=admin"   "$adminPassword"
    setUserPasswordInLdifFile "$DS_DATA_DIR/db/monitorUser/monitorUser.ldif" "uid=monitor" "$monitorPassword"
}

forgeopsInit() {
    # Make sure master keys and truststore are in place and up to date.
    copyKeys
    upgradeDataAndRebuildDegradedIndexes
    # Set the admin and monitor passwords from K8S secrets
    setAdminAndMonitorPasswords
    # Add app schema (forgeops add-schema hook; present in ds-idrepo scripts)
    if [ -x "./runtime-scripts/${POD_NAME%-*}/add-schema" ]; then
        ./runtime-scripts/${POD_NAME%-*}/add-schema
    fi
}

# Run one of the deployer-provided runtime-scripts (e.g. backup/restore).
# The image does not ship runtime-scripts; deployments supply them via
# mounted volumes/ConfigMaps at the well-known path. Executed directly (the
# shebang decides the interpreter): this image has no bash, so a script
# carrying a bash shebang must be supplied by the deployment -- the image's
# busybox-ash runtime cannot run it either way.
executeScript() {
    script="/opt/opendj/runtime-scripts/$1"
    if [ -f "$script" ]; then
        "$script"
    else
        log_error "Script ${script} not found - provide it via a mounted runtime-scripts directory"
        exit 1
    fi
}

# ---------- dispatch ----------

# Shared start path for both the "start-ds" and "start" commands (busybox ash
# lacks bash's ";&" case fallthrough, so the two arms share this function
# instead of falling through).
do_start() {
    remove_locks
    if [ "$MODE" = "base" ]; then
        validate_image
        bootstrap_data_from_image_if_needed
        link_keystore_and_data_directories
        use_file_keystore_crypto
        set_online_tool_properties
        upgrade_data_and_rebuild_untrusted_indexes
        set_admin_and_monitor_passwords_if_needed
        log_server_configuration
    else
        set_online_tool_properties
    fi
    exec start-ds --nodetach
}

CMD="${1:-help}"
case "$CMD" in

help)
    cat docker-entrypoint-help.md
    ;;

# start-ds and start are aliases in both modes
start-ds|start)
    do_start
    ;;

# init is run in an init container and prepares the directory for running.
initialize-only)
    if [ "$MODE" = "forgeops" ]; then
        if [ -d "$DS_DATA_DIR/db" ];  then
            log_info "data/ directory contains data. setup is not required";
            # Init still needs to check and rebuild indexes.
            forgeopsInit
            # If the user supplies a post-init script, run it. The default is a no-op.
            ./runtime-scripts/${POD_NAME%-*}/post-init
            exit 0
        fi
        # Else - no data is present, we need to run setup.
        log_info "Untaring prototype setup to $DS_DATA_DIR"
        tar -C "$DS_DATA_DIR" -xzf data.tar.gz
        copyKeys
        ./runtime-scripts/${POD_NAME%-*}/setup
        forgeopsInit
        ./runtime-scripts/${POD_NAME%-*}/post-init
        exit 0
    else
        DEBUG_LOGGING=${DEBUG_LOGGING:-true}
        validate_image
        bootstrap_data_from_image_if_needed
        link_keystore_and_data_directories
        use_file_keystore_crypto
        remove_locks
        upgrade_data_and_rebuild_untrusted_indexes
        set_admin_and_monitor_passwords_if_needed
        log_info "Initialization completed"
    fi
    ;;

backup)
    if [ ! -d "$DS_DATA_DIR/db" ]; then
        echo "There is no data to backup!";
        exit 1
    fi
    forgeopsInit
    executeScript backup
    ;;

restore)
    # restore needs access to the master keypair to decrypt data
    copyKeys
    executeScript restore
    ;;

dev-init)
    forgeopsInit
    # dev-init previously fell through to dev (busybox ash lacks ";&"), so it
    # waits for SIGTERM explicitly here.
    log_info "Connect using 'kubectl exec -it POD -- sh'"
    wait_until_sig_term
    ;;

dev)
    # Sleep until Kubernetes terminates the pod using a SIGTERM.
    log_info "Connect using 'kubectl exec -it POD -- sh'"
    wait_until_sig_term
    ;;

set-passwords-only)
    setAdminAndMonitorPasswords
    ;;

*)
    remove_locks
    if [ "$MODE" = "base" ]; then
        validate_image
        link_keystore_and_data_directories
        log_server_configuration
    fi
    shift
    exec "$@"
    ;;

esac
