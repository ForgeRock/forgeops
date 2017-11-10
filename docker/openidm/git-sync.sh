#!/usr/bin/env bash
# Sync git configuration upstream. This assumes that the git project has already been cloned.
# This is a convenience utility so we don't need to install another git sidecar.
# TODO: Consider deprecating this.

set -x
# Top level directory where git projects will be cloned to.
GIT_ROOT=${GIT_ROOT:=/git/config}


GIT_AUTOSAVE_BRANCH="${GIT_AUTOSAVE_BRANCH:-autosave-idm}"


cd "${GIT_ROOT}"

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

