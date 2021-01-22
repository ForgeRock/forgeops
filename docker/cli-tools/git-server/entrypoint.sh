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
    git init --bare --shared $GIT_DIR

    # TODO: Figure out how to prime this from the contents of forgeops/config/7.0/cdk
fi


if ! spawn-fcgi -s /srv/run/fcgiwrap.socket /usr/sbin/fcgiwrap;
then
    echo "Failed to start FCGI"
    exit
fi
exec nginx -g "daemon off;"
