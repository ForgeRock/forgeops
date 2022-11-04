#!/usr/bin/env bash
#  script to sync git directory

WORKSPACE="${WORKSPACE:-/git}"
REPO="${REPO:-fr-config}"
RPATH="$WORKSPACE/$REPO"

cd  "$RPATH" || {
    echo "Can not cd to $RPATH !"
    exit 1
}
BRANCH=$(git rev-parse --abbrev-ref HEAD)
REPO_SUBDIR="${REPO_SUBDIR:-$BRANCH}"

if [[ ! -d .git ]];
then
    echo "It looks like the git directory has not been initialized. I'll just pause"
    while true;
    do
        sleep 300
    done

fi

git config user.email "git-sync@forgerock.com"
git config user.name "FR git-sync"

# Try to switch to the branch and pull
cd "$REPO_SUBDIR" || {
        echo "Can cd to $REPO_SUBDIR"
        exit 1
}

while true; do
    sleep 30
    # Add any new files
    git add .
    # commit and push changes
    git commit -a -m "$BRANCH sync save"
    git push
done
