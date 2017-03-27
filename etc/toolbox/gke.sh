#!/usr/bin/env bash


eval $(minikube docker-env)


rm -fr docker/fretes

mkdir -p docker/fretes


cp -r ../{gke,helm} docker/fretes


docker build -t forgerock/toolbox docker

IMAGE=gcr.io/engineering-devops/toolbox:latest
docker tag forgerock/toolbox $IMAGE


gcloud docker -- push $IMAGE


export ZONE=us-central1-f

# gcloud compute --project "engineering-devops" disks create "disk-1" --size "100" --zone "us-central1-f" --type "pd-ssd"

