#!/usr/bin/env bash

eval $(minikube docker-env)

rm -fr docker/fretes

mkdir -p docker/fretes

cp -r ../{gke,helm} docker/fretes

docker build -t forgerock/toolbox docker

docker tag forgerock/toolbox docker-public.forgerock.io/forgerock/toolbox

docker push docker-public.forgerock.io/forgerock/toolbox



