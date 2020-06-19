#!/usr/bin/env bash
# Simple script to automatically restore DS from backups
# Note: This script assumes it runs in a k8s init-container with the proper volumes and environment variables attached.

# Required environmental variables: 
# AUTORESTORE_FROM_DSBACKUP: Set to true to restore from backup. Defaults to false
# GOOGLE_CREDENTIALS_JSON: Contents of the service account JSON, if using GCP. The SA must have write privileges in the desired bucket
# AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY: Access key and secret for AWS, if using S3. 
# AZURE_ACCOUNT_NAME, AZURE_ACCOUNT_KEY: Storage account name and key, if using Azure
# POD_NAME: Name of the current pod

set -e

if [ -n "$(ls -A /opt/opendj/data -I lost+found)" ]; then
  echo "Found data present in /opt/opendj/data before DS initialization"
  DATA_PRESENT_BEFORE_INIT="true"
  ls -A /opt/opendj/data -I lost+found
fi

##
# Initialize DS regarless of dsbackup restore settings
# /opt/opendj/docker-entrypoint.sh initialize-only
##

# Remove this section once support for SET_UID_ADMIN_AND_MONITOR_PASSWORDS is added
update_pw() {
     if [ ! -f "$1" ]; then
        echo "Can't find the password file $1. Won't change the password in $2"
        return
    fi

    echo "Updating the password in $2"
    # Set the JVM args so we dont blow up the container memory.
    pw=$(OPENDJ_JAVA_ARGS="-Xmx256m -Djava.security.egd=file:/dev/./urandom" bin/encode-password  -s "PBKDF2-HMAC-SHA256" -f $1 | sed -e 's/Encoded Password:  "//' -e 's/"//g' 2>/dev/null)
    # $pw can contian / - so need to use alternate sed delimiter.
    sed -ibak "s#userPassword: .*#userPassword: $pw#" "$2"
}

/opt/opendj/docker-entrypoint.sh initialize-only;

DS_UID_ADMIN_PASSWORD_FILE=${DS_UID_ADMIN_PASSWORD_FILE-"/var/run/secrets/opendj-passwords/dirmanager.pw"}
DS_UID_MONITOR_PASSWORD_FILE=${DS_UID_MONITOR_PASSWORD_FILE-"/var/run/secrets/opendj-passwords/monitor.pw"}
ROOT_USER_LDIF=${ROOT_USER_LDIF-"/opt/opendj/data/db/rootUser/rootUser.ldif"}
MONITOR_USER_LDIF=${MONITOR_USER_LDIF-"/opt/opendj/data/db/monitorUser/monitorUser.ldif"}
update_pw "$DS_UID_ADMIN_PASSWORD_FILE" "${ROOT_USER_LDIF}"
update_pw "$DS_UID_MONITOR_PASSWORD_FILE" "${MONITOR_USER_LDIF}"
###

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

case "$DSBACKUP_DIRECTORY" in 
  s3://* )
    echo "S3 Bucket detected. Restoring backups from AWS S3"
    EXTRA_PARAMS="${AWS_PARAMS}"
    BACKUP_LOCATION="${DSBACKUP_DIRECTORY}/${POD_NAME}"
    ;;
  az://* )
    echo "Azure Bucket detected. Restoring backups from Azure block storage"
    EXTRA_PARAMS="${AZ_PARAMS}"
    BACKUP_LOCATION="${DSBACKUP_DIRECTORY}/${POD_NAME}"
    ;;
  gs://* )
    echo "GCP Bucket detected. Restoring backups from GCP block storage"
    printf %s "$GOOGLE_CREDENTIALS_JSON" > ${GCP_CREDENTIAL_PATH}
    EXTRA_PARAMS="${GCP_PARAMS}"
    BACKUP_LOCATION="${DSBACKUP_DIRECTORY}/${POD_NAME}"
    ;;
  *)
    EXTRA_PARAMS=""
    BACKUP_LOCATION="${DSBACKUP_DIRECTORY}"
    ;;
esac  

echo "Attempting to restore backup from: ${BACKUP_LOCATION}"

BACKEND_NAMES=$(dsbackup list --last --verify --noPropertiesFile --backupLocation ${BACKUP_LOCATION} ${EXTRA_PARAMS} | 
    grep -i "backend name" | awk '{printf "%s %s ","--backendName", $3}')

if [ ! -z "${BACKEND_NAMES}" ]; then
    echo "Restore operation starting"
    dsbackup restore --offline --noPropertiesFile --backupLocation ${BACKUP_LOCATION} ${EXTRA_PARAMS} ${BACKEND_NAMES} 
    echo "Restore operation complete"
else
    echo "No Backup found in ${BACKUP_LOCATION}. There's nothing to restore"
fi

