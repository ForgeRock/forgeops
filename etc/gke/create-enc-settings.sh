#!/usr/bin/env bash
# Commands to execute to create encrypted settings.xml for maven

KEYRING=forgeops-build
KEY=maven-settings
SVC="1067706085367@cloudbuild.gserviceaccount.com"

gcloud kms keyrings create ${KEYRING} --location global

# Create a key for maven.
gcloud kms keys create ${KEY} \
  --location=global \
  --keyring=${KEYRING} \
  --purpose=encryption


# Grant cloudbuilder access.
gcloud kms keys add-iam-policy-binding \
    ${KEY} --location=global --keyring=${KEYRING} \
    --member=serviceAccount:${SVC} \
    --role=roles/cloudkms.cryptoKeyEncrypterDecrypter

# Encrypt the settings.xml.
gcloud kms encrypt \
  --plaintext-file=$HOME/.m2/settings.xml \
  --ciphertext-file=../../docker/settings.xml.enc \
  --location=global \
  --keyring=${KEYRING} \
  --key=${KEY}