#!/usr/bin/env sh
# Clone from git.
set -x


GIT_BRANCH=${GIT_CHECKOUT_BRANCH:-master}

ls -lR /etc/git-secret


# If GIT_REPO is defined, clone the configuration repo

if [ ! -z "${GIT_REPO}" ]; then

    mkdir -p "${GIT_ROOT}"
    cd ${GIT_ROOT}
    # sometimes the git repo emptyDir does not get cleaned up from a previous run
    rm -fr *
    git clone "${GIT_REPO}" "${GIT_ROOT}"
    if [ "$?" -ne 0 ]; then
       echo "git clone failed. Will sleep for 5 minutes for debugging."
       sleep 300
       exit 1
    fi
    cd "${GIT_ROOT}"
    git checkout "${GIT_BRANCH}"
    if [ "$?" -ne 0 ]; then
       echo "git checkout of ${GIT_BRANCH} failed. Will sleep for 5 min for debugging"
       sleep 300
       exit 1
    fi
fi

# Run optional sed substitutions. This is most commonly use to change the FQDN.
# For example:
# SED_FILTER="-e s/openam.foo.com/openam.bar.com/ -e s/baz.com/boo.com/"

if [ ! -z "$SED_FILTER" ]; then
    echo "Running sed replacement on checked out source using pattern $SED_FILTER"
    find .  \( ! -type d \) -exec sed -i $SED_FILTER {} \;
fi


