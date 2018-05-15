#!/usr/bin/env bash
# Copyright (c) 2016-2017 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file
#
# Sample script to create a Kubernetes cluster on Google Kubernetes Engine (GKE)
# You must have the gcloud command installed and access to a GCP project.
# See https://cloud.google.com/container-engine/docs/quickstart


# This is a sample of how to create a git ssh secret. 

# Generate the key pair
ssh-keygen -t rsa -C "forgeopsrobot@forgrock.com" -f id_rsa -N ''

kubectl delete secret git-ssh-key
# Create the secret. Note the file *must* be called id_rsa.
kubectl create secret generic git-ssh-key --from-file=id_rsa


echo "Upload id_rsa.pub to github or stash"
