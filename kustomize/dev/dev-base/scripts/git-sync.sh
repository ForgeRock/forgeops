#!/usr/bin/env bash
#  script to sync git directory

WORKSPACE="${WORKSPACE:-/git}"
REPO="${REPO:-fr-config}"
RPATH="$WORKSPACE/$REPO"

cd  "$RPATH" || {
    echo "Can not cd to $RPATH !"
    exit 1
}

if [[ ! -d .git ]];
then
    echo "It looks like the git directory has not been initialized. I'll just pause"
    while true;
    do
        sleep 300
    done

fi

git config user.email "git@forgeops"
git config user.name "Forgeops Sync"

while true; do
    sleep 30
    # Add any new files
    git add .
    # commit and push changes
    git commit -a -m "sync save"
    git push
done
