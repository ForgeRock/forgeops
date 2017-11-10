#!/usr/bin/env bash
# Sync git configuration upstream. This assumes that the git project has already been cloned.

set -x
# Top level directory where git projects will be cloned to.
GIT_ROOT=${GIT_ROOT:=/git/config}


GIT_AUTOSAVE_BRANCH="${GIT_AUTOSAVE_BRANCH:-autosave-am}"

cd "${GIT_ROOT}"

# This configures git to ignore file mode changes.
git config core.filemode false
git config user.email "auto-sync@forgerock.net"
git config user.name "Git Auto-sync user"

git checkout -B "${GIT_AUTOSAVE_BRANCH}"

t=`date`
git add .
git commit -a -m "autosave at $t"
git push --set-upstream origin ${GIT_AUTOSAVE_BRANCH} -f

