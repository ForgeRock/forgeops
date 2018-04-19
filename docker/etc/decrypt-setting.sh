#!/usr/bin/env bash
# If you need to perform maintenance on settings.xml file (to add a robot account for maven or registry access)
# This script will decrypt settings.xml.
# *DO NOT* check settings.xml into git. It is in the .gitignore file, so
# this should not happen.
gcloud kms decrypt \
    --ciphertext-file=settings.xml.enc \
    --plaintext-file=settings.xml \
    --location=global \
    --keyring=forgeops-build \
    --key=maven-settings

echo "When you are done editing settings.xml, reencrypt the file:"

echo gcloud kms encrypt \
    --ciphertext-file=settings.xml.enc \
    --plaintext-file=settings.xml \
    --location=global \
    --keyring=forgeops-build \
    --key=maven-settings