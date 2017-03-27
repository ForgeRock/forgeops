#!/usr/bin/env bash

kubectl delete -f toolbox.yaml

sleep 5

kubectl create -f toolbox.yaml


