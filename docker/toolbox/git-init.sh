#!/usr/bin/env sh
# Optionally execute this to checkout configuration source
# The container should have git and openssh-client installed

GIT_ROOT=${GIT_ROOT:=/git}

GIT_BRANCH=${GIT_BRANCH:-master}

# Dont default - in case we dont want to sync
#GIT_REPO=${GIT_REPO:-"https://stash.forgerock.org/scm/cloud/forgeops-init.git"}

# Note This is only used if the git repo is ssh
# It expects the git ssh key to be mounted at /etc/git-secret/ssh

export GIT_SSH_COMMAND="ssh -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i /etc/git-secret/ssh"

# If GIT_REPO is defined, clone the configuration repo

if [ ! -z "${GIT_REPO}" ]; then
    mkdir -p ${GIT_ROOT}
    cd ${GIT_ROOT}
    echo git clone -b "${GIT_BRANCH}"  "${GIT_REPO}"
    git clone -b "${GIT_BRANCH}"  "${GIT_REPO}"
    if [ "$?" -ne 0 ]; then
       echo "git clone failed"
       exit 1
    fi
fi