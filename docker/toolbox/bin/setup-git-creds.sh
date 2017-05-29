#!/usr/bin/env bash
# To run git clone from ForgeRock's private Stash repo, you need to create a ssh key for Stash.
key=~/.ssh/id_rsa


kubectl delete secret git-credentials
kubectl create secret generic git-credentials --from-file=ssh="${key}"

