#!/usr/bin/env bash

# validate password
[[ -z $GIT_USER_PASS ]] \
    && echo "GIT_USER_PASS env required this may not work but trying anyway"

if [[ -n $GIT_USER_PASS ]];
then
    encrypted=$(echo -n "${GIT_USER_PASS}" | openssl passwd -apr1 -stdin)
    echo "git:${encrypted}" > /srv/run/.htpasswd
fi
if ! spawn-fcgi -s /srv/run/fcgiwrap.socket /usr/sbin/fcgiwrap;
then
    echo "Failed to start FCGI"
    exit
fi
exec nginx -g "daemon off;"
