#!/usr/bin/env bash


# validate password
if [[ -z $GIT_USER_PASS ]];
then
    echo "Warning: GIT_USER_PASS env not set for the git user. I will use a default"
    export GIT_USER_PASS="forgerock"
fi


if [[ -n $GIT_USER_PASS ]];
then
    encrypted=$(echo -n "${GIT_USER_PASS}" | openssl passwd -apr1 -stdin)
    echo "git:${encrypted}" > /srv/run/.htpasswd
fi


# See if the pvc has git initialized. If not - do so now
if [[ ! -d  $GIT_DIR ]];
then
    echo "$GIT_DIR is empty. Initializing a bare git repo"


    mkdir -p /tmp/git
    cd /tmp/git
    DEST="$GIT_DIR"
    # Run in subshell and unset GIT_DIR!
    # This procedure initializes the bare repo with a master branch
    (
        unset GIT_DIR
        git init
        git config user.email "init@forgerock.com"
        git config user.name "Forgerock User"
        echo "Baseline Branch" >  README.md
        git add README.md
        git commit -a -m 'init'
        mkdir -p /srv/git
        mv .git $DEST
        cd $DEST
        git config --bool core.bare true
    )
fi


if ! spawn-fcgi -s /srv/run/fcgiwrap.socket /usr/sbin/fcgiwrap;
then
    echo "Failed to start FCGI"
    exit
fi
exec nginx -g "daemon off;"
