#!/usr/bin/env sh
# A sample script to export a configuration.

GIT_ROOT=${GIT_ROOT:-/git}
CONFIG_PATH=${CONFIG_PATH:-forgeops-init/openam/default}
GIT_SAVE_BRANCH=${GIT_SAVE_BRANCH:-am-autosave}


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
# TODO: Should the arg be params such as the branch, sleep interval, etc.?
if [ "$#" -gt 0 ]; then
    echo "Will perform export / git sync loop"
    cd ${P}
    git branch ${GIT_SAVE_BRANCH}
    git branch
    git checkout ${GIT_SAVE_BRANCH}
    while true
    do
       doExport
       git add .
       t=`date`
       git commit -a -m "Auto-saved configuration at $t"
       git push -f --set-upstream origin ${GIT_SAVE_BRANCH}
       sleep 60
   done
fi


# else we just perform a one time export and exit
doExport
