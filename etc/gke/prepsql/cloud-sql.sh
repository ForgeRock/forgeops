#!/usr/bin/env bash

# Cloud SQL instance name
INSTANCE=openidm1

# User and password used bu IDM to connect to the database.
PROXY_USER="idmuser"
PASSWORD="idmpassword"
#PROXY_USER="openidm"

# Kube namespace to create the secrets in.
NAMESPACE="default"

# Password to use for the super user (postgres) account.
PGPASSWORD="postgres"

# Path to downloaded service account json file.  This is a private key
# and should not be checked in to source control.
PROXY_KEY_FILE_PATH="../../../helm/tmp/EngineeringDevOps-pgkey.json"

# This creates the pg instance.
# For non shared instance types, you must set the CPU cores and memory together.
# CPU sizing -         --cpu=1 --memory=3840MiB \
gcloud sql instances create "${INSTANCE}" \
        --tier db-f1-micro  \
        --database-version=POSTGRES_9_6

# Set the password for the postgres user.
gcloud sql users set-password postgres no-host --instance="${INSTANCE}" \
       --password="${PGPASSWORD}"


# Create a proxy user that can connect to the instance.
gcloud sql users create "${PROXY_USER}" localhost --instance="${INSTANCE}" --password="${PASSWORD}"

# get instance name
gcloud sql instances describe "${INSTANCE}"


kubectl --namespace "${NAMESPACE}" delete secret cloudsql-instance-credentials

# Create instance secret
kubectl --namespace "${NAMESPACE}" create secret generic cloudsql-instance-credentials \
    --from-file=credentials.json="${PROXY_KEY_FILE_PATH}"

kubectl --namespace "${NAMESPACE}" delete secret  cloudsql-db-credentials

# Create the proxy user secret
kubectl --namespace "${NAMESPACE}" create secret generic cloudsql-db-credentials \
       --from-literal=username="${PROXY_USER}" --from-literal=password="${PASSWORD}"

kubectl --namespace "${NAMESPACE}" delete secret cloudsql-postgres-credentials

# postgres creds are needed to create the proxy user and database.
kubectl --namespace "${NAMESPACE}" create secret generic cloudsql-postgres-credentials \
     --from-literal=password="${PGPASSWORD}"


# Sample commands:
# Starting a stopped instance.
# gcloud sql instances patch [INSTANCE_NAME] --activation-policy ALWAYS


# Stop an instance.
# gcloud sql instances patch $INSTANCE --activation-policy NEVER


# Restart instance.
# gcloud sql instances restart $INSTANCE
