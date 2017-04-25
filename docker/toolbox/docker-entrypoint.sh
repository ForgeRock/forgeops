#!/usr/bin/env sh

# Clone any git repos if GIT_REPO is set
/opt/toolbox/bin/git-init.sh

echo "Cmd is $1"

echo "Initializing helm"

helm init

echo "Addding ForgeRock Helm Repo"
helm repo add forgerock https://storage.googleapis.com/forgerock-charts

export HELM_REPO=forgerock


# Try to guess what kind of cluster we are running on - and copy the right starter custom.yaml
node=minikube
kubectl get node | grep minikube  >/dev/null
if [ $? -ne 0 ]; 
then
    node=gke
fi

echo "It looks like you are running on a $node cluster"

echo "Creating default custom.yaml"

case $node in 
    minikube)   
        cp templates/custom.yaml .  ;;
    gke) 
        cp templates/custom-gke.yaml custom.yaml  ;;
esac 


do_pause() {
    echo "Sleeping" 
    while true
    do
        sleep 10000
    done 
}
# assume command is startall. TODO: add different entry points

case $1 in
startall)   
    bin/start-all.sh;;
    
pause) 
    do_pause ;;

*) 
    exec $@ ;;
esac


# todo: optionally run bin/startall.sh
