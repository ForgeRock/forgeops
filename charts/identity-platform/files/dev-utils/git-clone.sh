#!/usr/bin/env bash
# Script runs using the bitnami:git image. Performs a clone of the AM config from the cluster local repo
# If git is available, the config for AM will be pulled from that, otherwise it will come from the AM config in the base image
# The script tries its best to always put a basic config in place
# On completion, the contents of /git/fr-config (an emptyDir) will contain the config

# debug
# set -x
GIT_USER=git
GIT_PASSWORD="${GIT_PASSWORD:-forgerock}"
WORKSPACE="${WORKSPACE:-/git}"
REPO="fr-config"
GIT_URL="http://$GIT_USER:$GIT_PASSWORD@git-server/$REPO.git"
BRANCH="${BRANCH:-am}"
GIT_CONTINUE_ON_ERROR="${GIT_CONTINUE_ON_ERROR:-true}"
REPO_SUBDIR="${REPO_SUBDIR:-$BRANCH}"
REPO_PATH="$WORKSPACE/$REPO/$REPO_SUBDIR"
# The name of the config folder - this config for AM, and conf for IDM
CONFIG_DIR="${CONFIG_DIR:-config}"

# Copies in the base config if none is found in git. This config comes from /fbc
# Which is assumed to be the AM or IDM config image that was copied to /fbc in a previous init container
copy_base_config() {
    if [[ -d "/fbc/$CONFIG_DIR" ]];
    then
        mkdir -p "$REPO_PATH"
        echo "Copying prototype FBC /$CONFIG_DIR from base image"
        cp -r /fbc/.home*  "$REPO_PATH"
        cp -r /fbc/*  "$REPO_PATH"

    else
        echo "Can not find prototype configuration  in /fbc/$CONFIG_DIR!"
        exit 1
    fi
}

cd "$WORKSPACE" || {
    echo "Can not change to $WORKSPACE directory"
    exit 1
}

if [[ -d  "${REPO_PATH}" ]];
then
    echo "It looks like the git $REPO is already cloned"
    # This is not considered an error
    exit 0
fi

# Try the git server - if we can't find it, exit fast
# The curl trick avoids a very long timeout (~5 min) using the git command
curl --connect-timeout 30 --retry 2 --retry-max-time 30 "$GIT_URL" || {
    echo "Git server does not appear to be running. Carrying on without git"
    copy_base_config
    exit 0
}

# Attempt to clone the directory. In cases where the user might not have a git repo setup
# we can carry on. If possible, exit with a zero code so startup continues
git clone "$GIT_URL" || {
    echo "The git clone of $REPO failed with status $?"
    if [[ "$GIT_CONTINUE_ON_ERROR" == "true" ]];
    then
        echo "Startup will continue"
        copy_base_config
        exit 0
    fi
    echo "Error can not continue"
    exit 1
}
mkdir -p "$REPO_PATH"

# Try to switch to the branch and pull
cd "$REPO_PATH" || {
        echo "Can't cd to $REPO_PATH"
        exit 1
}

git config pull.rebase true
git config user.email "git-clone@forgerock.com"
git config user.name "FR git-clone"

# If the repo is fresh, these may fail - but ignore
git checkout "$BRANCH"
git pull

# The clone above may have worked, but the cloned directory might still be empty
if [[ ! -d "$REPO_PATH/$CONFIG_DIR" ]];
then
    echo "git clone looks like it is empty"
    copy_base_config

    git branch -a
    # Switch to the branch, or create it if missing
    git checkout "$BRANCH" || {
        echo "Branch $BRANCH does not exist. Creating it"
        git checkout -B "$BRANCH"
    }

    # Create a .gitignore file
    cat >.gitignore <<EOF
security
var
.homeVersion
EOF
    git add .gitignore
    git commit -a -m "$BRANCH first commit"
    git push  --set-upstream origin "$BRANCH"
fi


echo "done"
