#!/usr/bin/env sh

# Clone any git repos if GIT_REPO is set
/usr/local/bin/git-init.sh


echo "Cmd is $1"

echo "Initializing helm"

helm init

echo "Addding ForgeRock Helm Repo"
helm repo add https://storage.googleapis.com/forgerock-charts



# for now just pause...
while true
do
    sleep 10000
done

