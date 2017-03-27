#!/usr/bin/env bash
# Put commands here that setup the environment.
# todo: Validate this, add additiional env checks

brew install docker-machine docker-compose

brew install kubernetes-helm kubernetes-cli

brew cask install minikube

echo "Creating a Minikube VM"

minikube start --memory 8096

echo "Enabling the ingress controller"
minikube addons enable ingress



