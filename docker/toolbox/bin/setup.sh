#!/usr/bin/env bash
# Put commands here that setup the environment.
brew update

brew install docker-machine docker-compose kubernetes-helm kubernetes-cli

brew cask install minikube

echo "Creating a Minikube VM"

minikube start --memory 8096

echo "Enabling the ingress controller"
minikube addons enable ingress

helm init

# Not currently used - but in the future we may add charts here
helm repo add forgerock https://storage.googleapis.com/forgerock-charts/

