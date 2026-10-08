#!/bin/sh
#
# POSIX (busybox ash) variant of files/keystore/keystore-create.sh: the job
# template runs this script on the platform image the deployer selected --
# under platform.imageMode: forgeops that is an alpine pingam image (busybox
# ash, no bash). keytool and jq are on PATH in both image lines; every other
# construct here is POSIX already. See the bash version for the full
# documentation of the stale-secret probe (the marker logic below).

set -e

[ -z "$KEYSTORE_CONF_DIR" ] && KEYSTORE_CONF_DIR=/home/forgerock
[ -z "$KEYSTORE_CONF" ] && KEYSTORE_CONF=$KEYSTORE_CONF_DIR/keystore.json
[ -z "$KEYSTORE_TYPE" ] && KEYSTORE_TYPE=$(jq -r .storeType $KEYSTORE_CONF)
[ -z "$KEYSTORE_DIR" ] && KEYSTORE_DIR=/keystore
[ -z "$KEYSTORE" ] && KEYSTORE=$KEYSTORE_DIR/keystore.$KEYSTORE_TYPE
# Where the EXISTING keystore secret (optional mount) appears inside this
# container -- the job template mounts it at /keystore-existing.
[ -z "$EXISTING_DIR" ] && EXISTING_DIR=/keystore-existing

[ -z "$SECRETS_DIR" ] && SECRETS_DIR=/var/run/secrets/keystore
[ -z "$STOREPASS_FILE" ] && STOREPASS_FILE=$SECRETS_DIR/.storepass
[ -z "$KEYPASS_FILE" ] && KEYPASS_FILE=$SECRETS_DIR/.keypass
[ -z "$DSPASS_FILE" ] && DSPASS_FILE=$SECRETS_DIR/dirmanager.pw

[ -z "$STOREPASS" ] && STOREPASS=$(cat $STOREPASS_FILE)
[ -z "$KEYPASS" ] && KEYPASS=$(cat $KEYPASS_FILE)
[ -z "$DSPASS" ] && DSPASS=$(cat $DSPASS_FILE)

# The kubectl container that follows pushes $KEYSTORE into the keystore
# Secret with create-if-absent semantics (keystore_create.config.secret.replace
# defaults to false). If a PREVIOUS install left that Secret behind (e.g.
# after a failed --atomic install was uninstalled: the Secret is not part of
# the release manifest, so uninstall leaves it), its keystore is encrypted
# with THAT install's store password -- pushing nothing would leave the
# platform's components failing to open it ("Keystore was tampered with, or
# password was incorrect"). Probe the secret-mounted copy (if any) with the
# CURRENT password and mark the outcome for the push step.
MARKER=$KEYSTORE_DIR/.reuse-existing
rm -f "$MARKER"
EXISTING=$EXISTING_DIR/keystore.$KEYSTORE_TYPE
if [ -s "$EXISTING" ]; then
    if keytool -list -storepass "$STOREPASS" -storetype $KEYSTORE_TYPE -keystore "$EXISTING" >/dev/null 2>&1; then
        touch "$MARKER"
        echo "Existing keystore secret opens with the current store password; it will be reused."
    else
        echo "Existing keystore secret does NOT open with the current store password (stale secret from a previous install); it will be replaced."
    fi
fi

[ -f "$KEYSTORE" ] && rm -f "$KEYSTORE"

# Initialize keystore with $STOREPASS
echo "Initializing keystore $KEYSTORE..."
echo "$STOREPASS" | keytool -importpass -alias configstorepwd -storetype $KEYSTORE_TYPE -storepass $STOREPASS -keystore $KEYSTORE

# Import DS password
echo "Importing DS password..."
echo "$DSPASS" | keytool -importpass -alias dsameuserpwd -storetype $KEYSTORE_TYPE -storepass $STOREPASS -keystore $KEYSTORE

aliases=$(jq -r .keytoolAliases[].name $KEYSTORE_CONF)
for alias in $aliases; do
    cmd=$(jq -r ".keytoolAliases[] | select(.name==\"$alias\") | .cmd" $KEYSTORE_CONF)
    case $cmd in
        genkeypair|genseckey)
            args=$(jq -r ".keytoolAliases[] | select(.name==\"$alias\") | .args[]" $KEYSTORE_CONF | sed -e ':a;N;s/\n/ /;ba')
            echo "Executing '$cmd' command for '$alias' alias..."
            keytool -$cmd -alias $alias $args -storepass "$STOREPASS" -keypass "$KEYPASS" -storetype $KEYSTORE_TYPE -keystore $KEYSTORE
            ;;
        *)
            echo "Unknown/unsupported command '$cmd' for '$alias' alias!"
            ;;
    esac
done

echo "Listing keystore entries..."
keytool -list -storepass "$STOREPASS" -storetype $KEYSTORE_TYPE -keystore $KEYSTORE

exit 0
