#!/usr/bin/env sh
# Optionally execute this to checkout configuration source.
# The container has git and the openssh-client installed.

set -x

GIT_ROOT=${GIT_ROOT:=/git}

GIT_BRANCH=${GIT_BRANCH:-master}

# Note - this is only used if the git repo type is ssh.
# It expects the git ssh key to be mounted at /etc/git-secret/ssh.

export GIT_SSH_COMMAND="ssh -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i /etc/git-secret/ssh"

# If GIT_REPO is defined, clone the configuration repo.

if [ ! -z "${GIT_REPO}" ]; then
    git config --global user.email "git-sync@forgerock.net"
    git config --global user.name "Git sync user"

    mkdir -p ${GIT_ROOT}
    cd ${GIT_ROOT}

    git clone -b "${GIT_BRANCH}"  "${GIT_REPO}"
    if [ "$?" -ne 0 ]; then
       echo "git clone failed"
       exit 1
    fi
fi