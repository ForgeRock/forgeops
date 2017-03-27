#!/usr/bin/env sh

echo "Cmd is $1"

cd /data

echo "Cloning the intial stack-config repo"

git clone https://github.com/ForgeRock/stack-config.git

cd /data/stack-config

git pull

echo "Initializing helm"

helm init

# todo: How to build the docker images

# do we put the backstage credentials in the image?

# todo: create PVC for persisting data

cd /fretes/helm

bin/registry.sh

echo "This container will sleep now - waiting for you to exec into it and run commands."
echo "You should now exec into the toolbox pod by running the following command:"
echo "kubectl exec toolbox -it /bin/bash"
echo "See the README in the container."
echo "Try running helm/bin/openam.sh to start up OpenAM"

echo "If you are pulling images from the ForgeRock registry for the first time, this takes a *very* long time. Be patient."

while true
do
    sleep 1000
done
