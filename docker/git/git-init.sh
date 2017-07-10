#!/usr/bin/env sh
# Clone from git.
set -x

GIT_ROOT=${GIT_ROOT:=/git}

GIT_BRANCH=${GIT_CHECKOUT_BRANCH:-master}


export GIT_SSH_COMMAND="ssh -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i /etc/git-secret/ssh"

# If GIT_REPO is defined, clone the configuration repo

if [ ! -z "${GIT_REPO}" ]; then
    mkdir -p ${GIT_ROOT}
    cd ${GIT_ROOT}
    # sometimes the git repo emptyDir does not get cleaned up from a previous run
    rm -fr *
    git clone -b "${GIT_BRANCH}"  "${GIT_REPO}"
    if [ "$?" -ne 0 ]; then
       echo "git clone failed. Will sleep for 5 min for debugging"
       sleep 300
       exit 1
    fi
    cd *

    if [ "$?" -ne 0 ]; then
       echo "git clone failed"
       exit 1
    fi
fi