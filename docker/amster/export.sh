#!/usr/bin/env sh
# A sample script to export a configuration. This assumes that a volume is mounted
# on the CONFIG_DIR below.

CONFIG_DIR=/amster-config/stack-config/amster

# Add the following so git doesn't complain about any commits missing user name / email.
git config --global user.email "amster@example.com"
git config --global user.name "Amster Admin"

cd $CONFIG_DIR
# Disable mode checking. Hostpath mounts mess this up on VirtualBox.
git config core.fileMode false


# Create Amster export script.
cat > /tmp/export.amster <<EOF
connect -k  /var/secrets/amster/id_rsa http://openam/openam
export-config --path $CONFIG_DIR
:quit
EOF

# Do the export.
cd /var/tmp/amster
sh amster /tmp/export.amster

cd $CONFIG_DIR

git status






