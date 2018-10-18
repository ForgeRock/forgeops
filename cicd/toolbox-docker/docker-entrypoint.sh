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
    cd /workspace/forgeops

    echo "Sleeping awaiting your command"
    while true
    do
        git fetch
        MSG=$(git status)
        echo "Git message:"
        echo $MSG
        if [[ "$MSG" = *$GIT_UPTODATE* ]]; then
            echo "Branch is up to date, tests postponed"
        else
            echo "We have a change on master, running tests(Tests will ensure that master is updated)"
            cd /
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
