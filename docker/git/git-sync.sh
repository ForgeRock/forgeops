#!/usr/bin/env bash
# Sync git configuration upstream. This assumes that the git project has already been cloned.

set -x


GIT_AUTOSAVE_BRANCH="${GIT_AUTOSAVE_BRANCH:-autosave}"


export GIT_SSH_COMMAND="ssh -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i /etc/git-secret/ssh"


cd "${GIT_ROOT}"

# This configures git to ignore file mode changes.
git config core.filemode false
git config user.email "auto-sync@forgerock.net"
git config user.name "Git Auto-sync user"


git checkout -B "${GIT_AUTOSAVE_BRANCH}"

# todo: Consider adding back in an optional sleep/loop feature.
t=`date`
git add .
git commit -a -m "autosave at $t"
git push --set-upstream origin ${GIT_AUTOSAVE_BRANCH} -f

