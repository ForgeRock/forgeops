#!/usr/bin/env bash
# Sync git configuration upstream. This assumes that the git project has already been cloned.


cd /git/config 

DEF_BRANCH="autosave-${NAMESPACE}"

GIT_AUTOSAVE_BRANCH="${GIT_AUTOSAVE_BRANCH:-$DEF_BRANCH}"

# This configures git to ignore file mode changes.
git config core.filemode false
git config user.email "auto-sync@forgerock.net"
git config user.name "Git Auto-sync user"


git checkout -B "${GIT_AUTOSAVE_BRANCH}"

# todo: Consider adding back in an optional sleep/loop feature.
t=`date`
git add .
git commit -a -m "autosave at $t"
git push --set-upstream origin "${GIT_AUTOSAVE_BRANCH}" -f

