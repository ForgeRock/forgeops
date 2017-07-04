#!/usr/bin/env bash
# A sample script to export a configuration.

set -x

GIT_ROOT=${GIT_ROOT:-/git}

# This should be set by the downward API, but in case it isn't, default it.
NAMESPACE=${NAMESPACE:-default}

# This is where amster will export files. You may want to set this
# environment variable rather than accepting the default.
CONFIG_PATH=${CONFIG_PATH:-forgeops-init/${NAMESPACE}/openam/autosave}

P="${GIT_ROOT}/${CONFIG_PATH}"

mkdir -p ${P}

# Disable mode checking.
# When using hostPath mounts on VirtualBox the mode checks trigger differences. You dont need this unless you are using VBox hostPath mounts.
# git config core.fileMode false

# Create Amster export script.
cat > /tmp/export.amster <<EOF
connect -k  /var/secrets/amster/id_rsa http://openam/openam
export-config --path $P
:quit
EOF

# Do the intial export.
doExport() {
    /opt/amster/amster /tmp/export.amster
}

# If a command line arg is passed it is a flag to perform a git commit sync loop.
if [ "$#" -gt 0 ]; then
    echo "Will perform export sync loop"
    cd ${P}

    while true
    do
       doExport
       sleep 300
   done
fi


# else we just perform a one time export and exit
doExport
