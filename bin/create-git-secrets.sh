#!/usr/bin/env bash
# Copyright (c) 2016-2017 ForgeRock. All rights reserved.

# This is a sample of how to create a git ssh secret for configuration cloning.

# Generate the key pair
ssh-keygen -t rsa -C "forgeopsrobot@forgrock.com" -f id_rsa -N ''

kubectl delete secret git-ssh-key
# Create the secret. Note the file *must* be called id_rsa.
kubectl create secret generic git-ssh-key --from-file=id_rsa


echo "Upload id_rsa.pub to github or stash"
