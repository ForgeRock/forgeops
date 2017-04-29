#!/usr/bin/env sh
# A sample script to export a configuration.

GIT_ROOT=${GIT_ROOT:-/git}

CONFIG_PATH=${CONFIG_PATH:-forgeops-init/openam/default}

P="${GIT_ROOT}/${CONFIG_PATH}"

mkdir -p ${P}

cd $GIT_ROOT

# Disable mode checking.
# When using hostPath mounts on VirtualBox the mode checks trigger differences. You dont need this unless you are using VBox hostPath mounts.
# git config core.fileMode false


# Create Amster export script.
cat > /tmp/export.amster <<EOF
connect -k  /var/secrets/amster/id_rsa http://openam/openam
export-config --path $P
:quit
EOF

# Do the export.
cd /opt/amster
sh ./amster /tmp/export.amster





