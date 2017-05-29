#!/usr/bin/env bash
# Edit this based on your environment!

brew cask update
brew update

brew install docker-machine docker-compose kubernetes-helm kubernetes-cli

brew cask install minikube
# Install useful helm plugins
helm plugin install https://github.com/adamreese/helm-nuke

echo "Creating a Minikube VM"

minikube start --memory 8096 --kubernetes-version v1.6.3 

echo "Enabling the ingress controller"
minikube addons enable ingress

helm init

# Add ForgeRock chart repo.
helm repo add forgerock https://storage.googleapis.com/forgerock-charts/

git clone https://stash.forgerock.org/scm/cloud/forgeops.git

