#!/usr/bin/env bash

cd /opt/opendj
INCREMENTAL_CRON=${BACKUP_SCHEDULE:-0 * * * *}

# Set backup location whether locally or to cloud storage. Default: /opt/opendj/data/bak
if [ -z "${BACKUP_DIRECTORY}" ]; then
    echo "BACKUP_DIRECTORY must be specified. "
    echo "BACKUP_DIRECTORY can be set to: /local/path | s3://bucket/path | az://container/path | gs://bucket/path "
    exit -1
else
    echo "BACKUP_DIRECTORY is set to $BACKUP_DIRECTORY"
fi

# Get DS admin password
ADMIN_PASSWORD=$(cat ${DS_UID_ADMIN_PASSWORD_FILE})

# Get task name, if task with name already running, then cancel
TASK_NAME=${TASK_NAME:-"recurringBackupTask"}
echo "Attempting to cancel task: ${TASK_NAME}. Ignore errors if the task does not exist"
manage-tasks --cancel "${TASK_NAME}" --hostname "localhost" \
    --port 4444 --bindDN "uid=admin" \
    --bindPassword  "${ADMIN_PASSWORD}" --trustAll | grep -i "cancelled"

if [[ "$CANCEL" ]]; then
    exit -1
fi

# Cloud storage backup properties
AWS_PARAMS="--storageProperty s3.keyId.env.var:AWS_ACCESS_KEY_ID  --storageProperty s3.secret.env.var:AWS_SECRET_ACCESS_KEY"
AZ_PARAMS="--storageProperty az.accountName.env.var:AZURE_ACCOUNT_NAME  --storageProperty az.accountKey.env.var:AZURE_ACCOUNT_KEY"
GCP_CREDENTIAL_PATH="/var/run/secrets/cloud-credentials-cache/gcp-credentials.json"
GCP_PARAMS="--storageProperty gs.credentials.path:${GCP_CREDENTIAL_PATH}"
BACKUP_LOCATION="${BACKUP_DIRECTORY}/${HOSTNAME}"

case "$BACKUP_DIRECTORY" in 
    s3://* )
        echo "S3 Bucket detected. Setting up backups in AwS S3"
        EXTRA_PARAMS="${AWS_PARAMS}"
        ;;
    az://* )
        echo "Azure Bucket detected. Setting up backups in Azure block storage"
        EXTRA_PARAMS="${AZ_PARAMS}"
        ;;
    gs://* )
        echo "GCP Bucket detected. Setting up backups in GCP block storage"
        printf %s "$GOOGLE_CREDENTIALS_JSON" > ${GCP_CREDENTIAL_PATH}
        EXTRA_PARAMS="${GCP_PARAMS}"
        ;;
    *)
        EXTRA_PARAMS=""
        ;;
esac    

# Add optional backends to dsbackup command
if [ -n "${BACKENDS}" ]; then
    backends=($(echo "$BACKENDS" | awk '{split($0,arr,",")} {for (i in arr) {print arr[i]}}'))
    # Loop through pods and carry out dsbackup task
    for backend in "${backends[@]}"
    do
        EXTRA_PARAMS="${EXTRA_PARAMS} --backendName ${backend}"
    done 
fi

echo "Storing backups in ${BACKUP_LOCATION}"

dsbackup create \
    --hostname localhost \
    --port 4444 \
    --bindDN uid=admin \
    --bindPassword "${ADMIN_PASSWORD}" \
    --backupLocation "${BACKUP_LOCATION}" \
    --recurringTask "${INCREMENTAL_CRON}" \
    --taskId "${TASK_NAME}" \
    --trustAll \
    $EXTRA_PARAMS