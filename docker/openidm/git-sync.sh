#!/usr/bin/env bash
# Sync git configuration upstream. This assumes that the git project has already been cloned.

set -x
# Top level directory where git projects will be cloned to.
GIT_ROOT=${GIT_ROOT:=/git}
GIT_PROJECT_DIRECTORY="${GIT_PROJECT_DIRECTORY:-forgeops-init}"


GIT_AUTOSAVE_BRANCH="${GIT_AUTOSAVE_BRANCH:-autosave-idm}"

# Default time in seconds between commit / push.
INTERVAL=${GIT_PUSH_INTERVAL:-300}

export GIT_SSH_COMMAND="ssh -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i /etc/git-secret/ssh"


cd "${GIT_ROOT}/${GIT_PROJECT_DIRECTORY}"

# This configures git to ignore file mode changes.
git config core.filemode false
git config user.email "auto-sync@forgerock.net"
git config user.name "Git Auto-sync user"

git branch ${GIT_AUTOSAVE_BRANCH}
git branch
git checkout ${GIT_AUTOSAVE_BRANCH}

t=`date`
git add .
git commit -a -m "autosave at $t"
git push --set-upstream origin ${GIT_AUTOSAVE_BRANCH} -f

