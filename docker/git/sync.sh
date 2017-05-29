#!/usr/bin/env bash
# Sync git configuration upstream.

# Top level directory where git projects will be cloned to.
GIT_ROOT=${GIT_ROOT:=/git}

GIT_BRANCH=${GIT_BRANCH:-master}

# For testing - just echo commands.
#git="echo git"

git="git"

export GIT_SSH_COMMAND="ssh -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i /etc/git-secret/ssh"

# We don't know the name of the git repo that was cloned, but there should only be a single config directory under the GIT_ROOT.
cd ${GIT_ROOT}/*

pwd

$git branch autosave
$git branch
$git checkout autosave

while true 
do
    sleep 30
    t=`date`
    $git add .
    $git commit -a -m "autosave at $t"
    # Push is only supported if the upstream repo starts with ssh://
    # The expression below is bash, not always the same as sh.
    if [[ ${GIT_REPO} == ssh* ]]; 
    then
        # We use -f to force the upstream push. Revisit this.
        $git push --set-upstream origin autosave -f
    fi
done
