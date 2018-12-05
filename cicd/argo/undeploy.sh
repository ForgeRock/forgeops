#!/usr/bin/env bash

for app in $(argocd app list |  awk '{print $1;}'); do 
    argocd app delete $app
done
