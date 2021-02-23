#!/usr/bin/env bash
# Script runs using the bitnami:git image. Performs a clone of the repo from the cluster local repo
# The script then merges all branches using an octupus merge into the "export" branch

# debug
# set -x
GIT_USER=git
GIT_PASSWORD="${GIT_PASSWORD:-forgerock}"
WORKSPACE="${WORKSPACE:-/git}"
REPO="fr-config"
GIT_URL="http://$GIT_USER:$GIT_PASSWORD@git-server/$REPO.git"
BRANCH="${BRANCH:-export}"
REPO_PATH="$WORKSPACE/$REPO"

cd "$WORKSPACE" || {
    echo "Can not change to $WORKSPACE directory"
    exit 1
}

if [[ -d  "${REPO_PATH}" ]];
then
    echo "It looks like the git $REPO is already cloned"
    # This is not considered an error
else 
    # The repo is not present. We need to clone
    # Try the git server - if we can't find it, exit fast
    # The curl trick avoids a very long timeout (~5 min) using the git command
    curl --connect-timeout 30 --retry 2 --retry-max-time 30 "$GIT_URL" || {
        echo "Git server does not appear to be running. Cannot continue"
        exit 1
    }

    # Attempt to clone the directory. If not possible, exit with a a non-zero code
    git clone "$GIT_URL" || {
        echo "The git clone of $REPO failed with status $?"
        echo "Error can not continue"
        exit 1
    }
fi

# Try to switch to the branch and pull
 cd "$REPO_PATH" || {
        echo "Can't cd to $REPO_PATH"
        exit 1
}
git config pull.rebase false
git config user.email "git-merge@forgerock.com"
git config user.name "FR git-merge"
git fetch --all --prune
REMOTE_BRANCHES=$(git branch -r -l origin* --format="%(refname:strip=-1)" | grep -Evi "master|HEAD" | tr '\n' ' ')

# Switch to the branch, or create it if missing
git checkout "$BRANCH" || {
    echo "Branch $BRANCH does not exist. Creating it"
    git checkout -B "$BRANCH"
}
# Merge all remove branches into current branch
git pull origin $REMOTE_BRANCHES --no-edit --quiet
echo "done"
