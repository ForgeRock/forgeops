#!/usr/bin/env bash
# Sync git configuration upstream.

set -x
# Top level directory where git projects will be cloned to.
GIT_ROOT=${GIT_ROOT:=/git}

GIT_BRANCH=${GIT_BRANCH:-master}

GIT_AUTOSAVE_BRANCH=${GIT_AUTOSAVE_BRANCH:-autosave}


export GIT_SSH_COMMAND="ssh -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i /etc/git-secret/ssh"

# We don't know the name of the git repo that was cloned, but there should only be a single config directory under the GIT_ROOT.
cd ${GIT_ROOT}/*


# This configures git to ignore file mode changes.
git config core.filemode false
git config user.email "auto-sync@forgerock.net"
git config user.name "Git Auto-sync user"

git branch ${GIT_AUTOSAVE_BRANCH}
git branch
git checkout ${GIT_AUTOSAVE_BRANCH}

while true 
do
    sleep 180
    t=`date`
    git add .
    git commit -a -m "autosave at $t"
    # Push is only supported if the upstream repo starts with ssh://
    # The expression below is bash, not always the same as sh.
    if [[ ${GIT_REPO} == ssh* ]]; 
    then
        # We use -f to force the upstream push. Revisit this.
        git push --set-upstream origin ${GIT_AUTOSAVE_BRANCH} -f
    fi
done
