#!/usr/bin/env bash
# Sample setup for macOs. 
# Edit this based on your environment! 
# Prerequisites: you must have homebrew installed.
brew update

# If you installed VirtualBox via the downloaded .dmg, you may find minikube
# won't start due to permissions. Installing via brew fixes this up:
brew cask install virtualbox

brew install docker-machine docker-compose kubernetes-helm kubernetes-cli git

brew cask install minikube

echo "Creating a Minikube VM"

# The command below defaults to using VirtualBox - which we assume you have installed.
# Add the --vm-driver=vmwarefusion  or --vm-driver=xhyve  if you want to change the hypervisor.
minikube start --memory 8096

minikube status

echo "Enabling the ingress controller"
minikube addons enable ingress

helm init

minikube dashboard

