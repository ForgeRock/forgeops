#!/usr/bin/env bash
# Does a one shot export of the AM configuration. This assumes the project has already been checked out.

set -x

GIT_ROOT=${GIT_ROOT:-/git/config}

# This should be set by the downward API, but in case it isn't, default it.
NAMESPACE=${NAMESPACE:-default}

# Needed for any git ssh commands.
export GIT_SSH_COMMAND="ssh -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i /etc/git-secret/ssh"

# Default export path - relative to the root.
export EXPORT_PATH="${EXPORT_PATH:-${NAMESPACE}/am/export}"

cd "${GIT_ROOT}"

git config core.filemode false
git config user.email "auto-sync@forgerock.net"
git config user.name "Git Auto-sync user"

git branch ${GIT_AUTOSAVE_BRANCH}
git checkout ${GIT_AUTOSAVE_BRANCH}

export AMSTER_EXPORT_PATH="${GIT_ROOT}/${EXPORT_PATH}"


mkdir -p "${AMSTER_EXPORT_PATH}"

# Create Amster export script.
cat > /tmp/do_export.amster <<EOF
connect -k  /var/run/secrets/amster/id_rsa http://openam/openam
export-config --path $AMSTER_EXPORT_PATH
:quit
EOF


/opt/amster/amster /tmp/do_export.amster
