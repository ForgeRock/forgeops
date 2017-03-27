#!/usr/bin/env bash
# Script to automate setting up the environment for the ForgeRock Minikube examples.
# You must have  the following installed:
#  VirtualBox, Minikube, the kubectl command. Install with:
# brew install kuberntes-cli
# brew cask install minikube
# start minikibe with:
# minikube start --memory=8096
#
# You must enable the Minikube ingress controller:
# minikube addons enable ingress
#
# If you do not want to enter your BackStage credentials in the script below, set the
# environment variables REGISTRY_ID and REGISTRY_PASSWORD

echo "Deleting any old toolbox pods. Ignore any errors you see below"

kubectl delete pod toolbox

if [ -z ${REGISTRY_ID+x} ];  then
    echo -n "REGISTRY_ID env variable is not set. Enter your registry id (backstage id) "
    read REGISTRY_ID
fi

if [ -z ${REGISTRY_PASSWORD+x} ];  then
    echo -n "REGISTRY_PASSWORD env variable not set. Enter your registry password (backstage password) "
    read REGISTRY_PASSWORD
fi

echo "Logging in to the registry docker-public.forgerock.io"

docker login -u "${REGISTRY_ID}" -p "${REGISTRY_PASSWORD}"  docker-public.forgerock.io

if [ $? -ne 0 ]; then
    echo "docker login failed. Please check your registry credentials and try again"
    exit 1
fi

docker pull docker-public.forgerock.io/forgerock/toolbox:latest

if [ $? -ne 0 ]; then
    echo "docker pull of docker-public.forgerock.io/forgerock/toolbox:latest failed."
    exit 1
fi

cat  <<EOF | sed -e s/XXXX/${REGISTRY_ID}/ -e s/YYYY/${REGISTRY_PASSWORD}/  >/tmp/toolbox.yaml
apiVersion: v1
kind: Pod
metadata:
  name: toolbox
  labels:
    name: toolbox
spec:
  restartPolicy: Never
  terminationGracePeriodSeconds: 2
  containers:
  - name: toolbox
    image: docker-public.forgerock.io/forgerock/toolbox:latest
    imagePullPolicy: IfNotPresent
    env:
    - name: REGISTRY_ID
      value: "XXXX"
    - name: REGISTRY_PASSWORD
      value: "YYYY"
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    hostPath:
      path: /data/work
EOF

red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`

echo "Creating the toolbox pod with Helm commands installed"

kubectl create -f /tmp/toolbox.yaml

sleep 5

echo -e "\n${red}****** You can kill this script (Control-c) when you see the kubectl exec command instructions printed below *******${reset} \n"

kubectl logs toolbox -f &
PID=$!

sleep 30

kill $PID

echo "Script exiting. Log on to the toolbox using: kubectl exec toolbox -it /bin/bash"
