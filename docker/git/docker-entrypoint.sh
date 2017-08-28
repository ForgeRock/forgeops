#!/bin/sh
# This container can be used as an init container to check out configuration from git,
# or as a sync container - to push changes to a git repo.


#git config --global core.filemode false

echo "Command is $1"

pause() {
    while true
    do
        echo "Sleeping"
        sleep 100000
    done
}

# This is as of yet an experimental (unpublished) service that syncs configuration.
# You can replace this with your own binary
frsync () {
    if [ -x /opt/forgerock/frconfigsrv ]; then
        echo "Running frconfig service"
        /opt/forgerock/frconfigsrv
    fi
}

case "$1" in
"init")
    exec /git-init.sh
    ;;
"sync")
    exec /git-sync.sh
    ;;
"init-sync")
     /git-init.sh
     exec /git-sync.sh
    ;;
"pause")
    pause
    ;;
"frsync")
    frsync
    pause
    ;;
*)
    exec $*
    ;;
esac




