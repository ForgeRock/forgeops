#!/usr/bin/env bash

cd /opt/opendj
FULL_CRON="0 0 * * *"
INCREMENTAL_CRON=${BACKUP_SCHEDULE:-0 * * * *}

# TODO This is a temporary workaround. taskIds are randmonly generated. see OPENDJ-7141. Need to obtain the name of the task, then cancel it.
echo "Cancelling any previously scheduled backup tasks. Ignore errors if the task does not exist"
TASK_NAME=$(manage-tasks --summary --hostname "${FQDN_DS0:-localhost}" --port 4444 --bindDN "uid=admin" --bindPassword  "${ADMIN_PASSWORD}" --trustAll | grep -i backuptask -m 1| awk '{print $1;}')
if [ ${TASK_NAME} ]; then 
  echo "Cancelling task: ${TASK_NAME}"
  manage-tasks --cancel "${TASK_NAME}" --hostname "${FQDN_DS0:-localhost}" --port 4444 --bindDN "uid=admin" --bindPassword  "${ADMIN_PASSWORD}" --trustAll | grep -i backuptask -m 1| awk '{print $1;}'
fi

AWS_PARAMS="--storageProperty s3.keyId.env.var:AWS_ACCESS_KEY_ID  --storageProperty s3.secret.env.var:AWS_SECRET_ACCESS_KEY"
AZ_PARAMS="--storageProperty az.accountName.env.var:AZURE_ACCOUNT_NAME  --storageProperty az.accountKey.env.var:AZURE_ACCOUNT_KEY"
GCP_CREDENTIAL_PATH="/var/tmp/gcp-credentials.json"
GCP_PARAMS="--storageProperty gs.credentials.path:${GCP_CREDENTIAL_PATH}"
EXTRA_PARAMS=""

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

echo "Storing backups in ${BACKUP_DIRECTORY}"

dsbackup create \
 --hostname "${FQDN_DS0:-localhost}" \
 --port 4444 \
 --bindDN uid=admin \
 --bindPassword "${ADMIN_PASSWORD}" \
 --backupLocation "${BACKUP_DIRECTORY}" \
 --recurringTask "${INCREMENTAL_CRON}" \
 --trustAll \
 $EXTRA_PARAMS