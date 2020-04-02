#!/usr/bin/env bash

set -euo pipefail

update_pw() {
     if [ ! -f "$1" ]; then
        echo "Can't find the password file $1. Won't change the password in $2"
        return
    fi

    echo "Updating the password in $2"
    # Set the JVM args so we dont blow up the container memory.
    pw=$(OPENDJ_JAVA_ARGS="-Xmx256m -Djava.security.egd=file:/dev/./urandom" bin/encode-password  -s "PBKDF2-HMAC-SHA256" -f $1 | sed -e 's/Encoded Password:  "//' -e 's/"//g' 2>/dev/null)
    # $pw can contian / - so need to use alternate sed delimiter.
    sed -ibak "s#userPassword: .*#userPassword: $pw#" "$2"
}

/opt/opendj/docker-entrypoint.sh initialize-only

DIR_MANAGER_PW_FILE=${DIR_MANAGER_PW_FILE-"/var/run/secrets/opendj-passwords/dirmanager.pw"}
MONITOR_PW_FILE=${MONITOR_PW_FILE-"/var/run/secrets/opendj-passwords/monitor.pw"}
ROOT_USER_LDIF=${ROOT_USER_LDIF-"/opt/opendj/data/db/rootUser/rootUser.ldif"}
MONITOR_USER_LDIF=${MONITOR_USER_LDIF-"/opt/opendj/data/db/monitorUser/monitorUser.ldif"}

update_pw "$DIR_MANAGER_PW_FILE" "${ROOT_USER_LDIF}"
update_pw "$MONITOR_PW_FILE" "${MONITOR_USER_LDIF}"

echo "ds-init.sh complete."
