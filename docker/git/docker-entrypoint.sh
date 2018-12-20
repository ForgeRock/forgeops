#!/bin/bash
# This container can be used as an init container to check out configuration from git,
# or as a sync container - to push changes to a git repo.

echo "Command is $1"

pause() {
    while true
    do
        echo "Sleeping"
        sleep 100000 & wait
    done
}

exit_script() {
    echo "Got signal"
    trap - SIGINT SIGTERM # clear the trap
    kill -- -$$ # Sends SIGTERM to child/sub processes
    echo "Exiting"
    exit 0
}

trap exit_script SIGINT SIGTERM SIGUSR1 EXIT

git_config() 
{
    cd /git/config
    git config core.filemode false
    git config user.email "auto-sync@forgerock.net"
    git config user.name "Git Auto-sync user"
}

TIME=300

syncloop() {
    echo "Will commit and push changes every $TIME seconds"
    while true
    do
        sleep $TIME & wait
        /git-sync.sh
    done
}



case "$1" in
"init")
    /git-init.sh
    ;;
"sync")
    git_config
    /git-sync.sh
    ;;
"init-sync")
     /git-init.sh
     git_config
     /git-sync.sh
    ;;
"pause")
    pause
    ;;
"syncloop")
    git_config
    syncloop
    ;;
*)
    exec $*
    ;;
esac
