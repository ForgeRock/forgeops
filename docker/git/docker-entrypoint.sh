#!/bin/sh
# This container can be used as an init container to check out configuration from git,
# or as a sync container - to push changes to a git repo.

# This is done in the Dockerfile, but we may remove it in the future - so no harm in repeating
# the commands here.
git config --global user.email "auto-sync@forgerock.net"
git config --global user.name "Git Auto-sync user"
git config --global core.filemode false

echo "Command is $1"
if [ "$1" = 'init' ]; then
    exec /git-init.sh
fi

# else .... 
exec /sync.sh 



