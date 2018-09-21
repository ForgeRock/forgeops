#!/usr/bin/env bash


echo "Cmd is $1"

echo "Cloning forgeops"
cd /
git clone https://github.com/ForgeRock/forgeops.git 

# configure context so kubens does not complain
kubectl config set-context default
kubectl config use-context default 


pause() {
    echo "Sleeping awaiting your command" 
    while true
    do
        sleep 10000
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


