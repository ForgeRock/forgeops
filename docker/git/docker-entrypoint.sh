#!/bin/sh
# This container can be used as an init container to check out configuration from git,
# or as a sync container - to push changes to a git repo.


#git config --global core.filemode false

echo "Command is $1"

case "$1" in
"init")
    exec /git-init.sh
    ;;
"sync")
    exec /sync.sh
    ;;
"init-sync")
     /git-init.sh
     exec /sync.sh
    ;;
*)
    exec $*
    ;;
esac




