#!/usr/bin/env sh
# Clone from git.
set -x


GIT_BRANCH=${GIT_CHECKOUT_BRANCH:-master}

# If GIT_REPO is defined, clone the configuration repo

if [ ! -z "${GIT_REPO}" ]; then

    mkdir -p "${GIT_ROOT}"
    cd ${GIT_ROOT}
    
    # Only clone the git repo if it does not already exist.
    if [ ! -d .git  ];
    then 
        git clone "${GIT_REPO}" "${GIT_ROOT}"
        git remote set-url --push origin no-pushing
        git config --add remote.origin.fetch '+refs/pull-requests/*/from:refs/remotes/origin/pr/*'
        git fetch
        if [ "$?" -ne 0 ]; then
            echo "git clone failed. Will sleep for 5 minutes for debugging."
            sleep 300
            exit 1
        fi
    fi
  
    git checkout "${GIT_BRANCH}"
    if [ "$?" -ne 0 ]; then
       echo "git checkout of ${GIT_BRANCH} failed. Will sleep for 5 min for debugging"
       sleep 300
       exit 1
    fi
fi

# Run optional sed substitutions. This is most commonly use to change the FQDN.
# For example:
# SED_FILTER="-e s/login.foo.com/login.bar.com/ -e s/baz.com/boo.com/"

if [ ! -z "$SED_FILTER" ]; then
    echo "Running sed replacement on checked out source using pattern $SED_FILTER"
    echo $SED_FILTER >/tmp/sedfilter
    cat /tmp/sedfilter
    find . -type f -exec sed -i -f /tmp/sedfilter {} \;
fi
