#!/usr/bin/env sh
# Checkout from git

GIT_ROOT=${GIT_ROOT:=/git}

GIT_BRANCH=${GIT_BRANCH:-master}

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