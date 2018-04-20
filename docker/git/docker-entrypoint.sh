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

TIME=300

syncloop() {
    echo "Will commit and push changes every $TIME seconds"
    while true
    do
        sleep $TIME
        /git-sync.sh
    done
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
"syncloop")
    syncloop
    ;;
*)
    exec $*
    ;;
esac




