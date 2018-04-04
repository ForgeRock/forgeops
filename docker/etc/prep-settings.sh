#!/usr/bin/env bash
# Utility commands used to encrypt / decrypt the settings.xml file
# Command to decrypt the settings file
gcloud kms decrypt --ciphertext-file=settings.xml.enc --plaintext-file=settings.xml \
     --location=global --keyring=forgeops-build --key=maven-settings

# Command to reencrypt setting.xml

gcloud kms encrypt --ciphertext-file=settings.xml.enc --plaintext-file=settings.xml \
     --location=global --keyring=forgeops-build --key=maven-settings