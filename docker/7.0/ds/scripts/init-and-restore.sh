#!/usr/bin/env bash
# Simple script to automatically restore DS from backups
# Note: This script assumes it runs in a k8s init-container with the proper volumes and environment variables attached.

# Required environmental variables: 
# AUTORESTORE_FROM_DSBACKUP: Set to true to restore from backup. Defaults to false
# GOOGLE_CREDENTIALS_JSON: Contents of the service account JSON, if using GCP. The SA must have write privileges in the desired bucket
# AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY: Access key and secret for AWS, if using S3. 
# AZURE_ACCOUNT_NAME, AZURE_ACCOUNT_KEY: Storage account name and key, if using Azure

set -e

if [ -n "$(ls -A /opt/opendj/data -I lost+found)" ]; then
  echo "Found data present in /opt/opendj/data before DS initialization"
  DATA_PRESENT_BEFORE_INIT="true"
  ls -A /opt/opendj/data -I lost+found
fi

# Initialize DS regarless of dsbackup restore settings
/opt/opendj/docker-entrypoint.sh initialize-only;

if [ -z "${AUTORESTORE_FROM_DSBACKUP}" ] || [ "${AUTORESTORE_FROM_DSBACKUP}" != "true" ]; then
    echo "AUTORESTORE_FROM_DSBACKUP is missing or not set to true. Skipping restore"
    exit 0
else
    echo "AUTORESTORE_FROM_DSBACKUP is set to true. Will attempt to recover from backup"
fi

if [ -z "${DSBACKUP_DIRECTORY}" ]; then
    echo "If AUTORESTORE_FROM_DSBACKUP is enabled, DSBACKUP_DIRECTORY must be specified. "
    echo "DSBACKUP_DIRECTORY can be set to: /local/path | s3://bucket/path | az://bucket/path | gs://bucket/path "
    exit -1
else
    echo "DSBACKUP_DIRECTORY is set to $DSBACKUP_DIRECTORY"
fi

if [ -z "${DSBACKUP_HOSTS}" ]; then
    echo "If AUTORESTORE_FROM_DSBACKUP is enabled, DSBACKUP_HOSTS must be specified. "
    echo "DSBACKUP_HOSTS should contain the pod names. Example: 'ds-cts-0,ds-idrepo-0'"
    exit -1
else
    echo "DSBACKUP_HOSTS is set to $DSBACKUP_HOSTS"
fi

if [ -n "${DATA_PRESENT_BEFORE_INIT}" ] && [ "${DATA_PRESENT_BEFORE_INIT}" != "false" ]; then
   echo "****"
   echo "There's data already present in /opt/opendj/data. Skipping restore operation." 
   echo "****"
   exit 0
fi

AWS_PARAMS="--storageProperty s3.keyId.env.var:AWS_ACCESS_KEY_ID  --storageProperty s3.secret.env.var:AWS_SECRET_ACCESS_KEY"
AZ_PARAMS="--storageProperty az.accountName.env.var:AZURE_ACCOUNT_NAME  --storageProperty az.accountKey.env.var:AZURE_ACCOUNT_KEY"
GCP_CREDENTIAL_PATH="/var/run/secrets/cloud-credentials-cache/gcp-credentials.json"
GCP_PARAMS="--storageProperty gs.credentials.path:${GCP_CREDENTIAL_PATH}"
EXTRA_PARAMS=""

# Let's convert the comma separated value in $DSBACKUP_HOSTS to an array
HOSTS=($(echo "${DSBACKUP_HOSTS}" | awk '{split($0,arr,",")} {for (i in arr) {print arr[i]}}'))


case "$DSBACKUP_DIRECTORY" in 
s3://* )
    echo "S3 Bucket detected. Restoring backups from AWS S3"
    EXTRA_PARAMS="${AWS_PARAMS}"
    ;;
az://* )
    echo "Azure Bucket detected. Restoring backups from Azure block storage"
    EXTRA_PARAMS="${AZ_PARAMS}"
    ;;
gs://* )
    echo "GCP Bucket detected. Restoring backups from GCP block storage"
    printf %s "$GOOGLE_CREDENTIALS_JSON" > ${GCP_CREDENTIAL_PATH}
    EXTRA_PARAMS="${GCP_PARAMS}"
    ;;
*)
    echo "Restoring backups from local storage"
    EXTRA_PARAMS=""
    ;;
esac  
# Recover from the first available backup that passes verification checks.
for host in "${HOSTS[@]}"; do
    # Remove the pod idx and compare. ex. ds-idrepo-2 => ds-idrepo-
    # if ds-idrepo- = ds-idrepo-, then attemp to restore from that $host backup
    if [ "$(printf ${HOSTNAME} | sed 's/[0-9]\+$//')" = "$(printf ${host} | sed 's/[0-9]\+$//')" ]; then
        BACKUP_NAME="${host}"
        BACKUP_LOCATION="${DSBACKUP_DIRECTORY}/${BACKUP_NAME}"

        echo "Attempting to verify backup from: ${BACKUP_LOCATION}"
        # If this host owns a backup task, restore the `tasks` backend. Else, skip the `tasks` backend
        if [[ " ${HOSTS[@]} " =~ " ${HOSTNAME} " ]]; then
        BACKEND_NAMES=$(dsbackup list --last --verify --noPropertiesFile --backupLocation ${BACKUP_LOCATION} ${EXTRA_PARAMS} | 
            grep -i "backend name" | awk '{printf "%s %s ","--backendName", $3}')
        else
        BACKEND_NAMES=$(dsbackup list --last --verify --noPropertiesFile --backupLocation ${BACKUP_LOCATION} ${EXTRA_PARAMS} | 
            grep -i "backend name" | grep -v "tasks" | awk '{printf "%s %s ","--backendName", $3}')
        fi
        if [ ! -z "${BACKEND_NAMES}" ]; then
            # Verification complete, we will use $BACKUP_LOCATION for restore
            break
        fi
    fi
done

if [ -z "${BACKUP_NAME}" ]; then
    echo "No suitable backup target was found for $HOSTNAME. Skipping restore"
    exit 0
else
    echo "BACKUP_NAME is set to $BACKUP_NAME"
fi

if [ ! -z "${BACKEND_NAMES}" ]; then
    echo "Verification completed."
    echo "Restoring backups from: ${BACKUP_LOCATION}"
    echo "Restoring ${BACKEND_NAMES}"
    dsbackup restore --offline --noPropertiesFile --backupLocation ${BACKUP_LOCATION} ${EXTRA_PARAMS} ${BACKEND_NAMES} 
    echo "Restore operation complete"
else
    echo "No Backup found in ${BACKUP_LOCATION}. There's nothing to restore"
fi

