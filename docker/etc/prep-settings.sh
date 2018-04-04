#!/usr/bin/env bash
# Utility commands used to encrypt / decrypt the settings.xml file.


# Decrypt.
gcloud kms decrypt --ciphertext-file=settings.xml.enc --plaintext-file=settings.xml \
     --location=global --keyring=forgeops-build --key=maven-settings

# Encrypt.
gcloud kms encrypt --ciphertext-file=settings.xml.enc --plaintext-file=settings.xml \
     --location=global --keyring=forgeops-build --key=maven-settings