#!/usr/bin/env bash


echo "Cmd is $1"

echo "Cloning forgeops"
mkdir -p /workspace

cd /workspace
git clone https://github.com/ForgeRock/forgeops.git

# configure context so kubens does not complain
kubectl config set-context default
kubectl config use-context default


pause() {
    GIT_UPTODATE="Your branch is up to date with 'origin/master'"

    while true
    do
        cd /workspace/forgeops
        git fetch
        MSG=$(git status)
        echo "$(date) - Git message:"
        echo $MSG
        if [[ "$MSG" = *$GIT_UPTODATE* ]]; then
            echo "$(date): Branch is up to date, tests postponed"
        else
            echo "$(date): We have a change on master, updating forgeops"
            git fetch -a; git reset --hard origin/master
            cd /
            echo "$(date): Waiting 20 minutes to make sure new images are built properly"
            sleep 1200
            ./run-smoke-tests.sh
        fi
        sleep 600
    done
}
# assume command is startall. TODO: add different entry points

case $1 in
smoke-tests)
    /run-smoke-tests.sh
    ;;

pause)
    pause ;;

*)
    exec $@ ;;
esac
