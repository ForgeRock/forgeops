#!/usr/bin/env bash
# To run git clone from ForgeRock's private Stash repo, you need to create a ssh key for Stash.
key=~/.ssh/id_rsa

kubectl create secret generic git-creds --from-file=ssh="${key}"

