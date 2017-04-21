#!/usr/bin/env bash

kubectl create -f toolbox-gke.yaml 
echo "Waiting for toolbox pod to come up"
sleep 15
echo "The ForgeRock Stack is being provisioned"
kubectl logs toolbox -f

