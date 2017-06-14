#!/usr/bin/env bash
# Edit this based on your environment!
# Prerequisites: you must have VirtualBox and homebrew installed.
brew update

brew install docker-machine docker-compose kubernetes-helm kubernetes-cli git

brew cask install minikube

echo "Creating a Minikube VM"

# The command below defaults to using VirtualBox - which we assume you have installed
# Add the --vm-driver=vmwarefusion  or --vm-driver=xhyve  if you want to change the hypervisor.
minikube start --memory 8096 --kubernetes-version v1.6.4

echo "Enabling the ingress controller"
minikube addons enable ingress

helm init

# Install useful helm plugins
helm plugin install https://github.com/adamreese/helm-nuke


# Add ForgeRock chart repo.
helm repo add forgerock https://storage.googleapis.com/forgerock-charts/

git clone https://stash.forgerock.org/scm/cloud/forgeops.git


minikube dashboard

