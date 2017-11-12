#!/usr/bin/env sh

echo "Cmd is $1"

echo "Initializing helm"

# This will start a tiller pod if it is not already running. TODO: Test for tiller first
helm init

# Try to guess what kind of cluster we are running on - and copy the right starter custom.yaml
node=minikube
kubectl get node | grep minikube  >/dev/null
if [ $? -ne 0 ]; 
then
    node=gke
fi

echo "It looks like you are running on a $node cluster"


do_pause() {
    echo "Sleeping" 
    while true
    do
        sleep 10000
    done 
}


case $1 in
bootstrap)
    bin/bootstrap.sh
    do_pause ;;
    
pause) 
    do_pause ;;

*) 
    exec $@ ;;
esac
