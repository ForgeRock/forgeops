#!/usr/bin/env bash
# Simplified script used by the operator to automatically initialize and restore DS from backups
# Note: This script assumes it runs in a k8s init-container with the proper volumes and environment variables attached.

# Restore strategy:
# If the operators spec.restore.enabled is true the operator passes spec.restore.path to this script.
# It restores the last backup it finds at the spec.restore.path, using the secret cloud-storage-credentials
# to talk to the various cloud storage services
# The argument passed to this script should be the path to restore from. For example, gs://my-ds/my-backup/
# If no path is passed on the command line, a normal start is assumed and no recovery will be attempted.

BACKUP_PATH="$1"
# If no restore path provided just perform init and exit
if [ -z "$BACKUP_PATH" ]; then
  echo "Initializing"
  exec /opt/opendj/docker-entrypoint.sh initialize-only;
fi

# Check for existing data on the pvc. This must be done before the data/db is initialized
if [ -d /opt/opendj/data/db/adminRoot ]; then
  echo "Data present in /opt/opendj/data before DS initialization. Skipping restore to avoid destroying data"
  exec /opt/opendj/docker-entrypoint.sh initialize-only;
fi

# Initialize the DS backends from the prototype docker database
/opt/opendj/docker-entrypoint.sh initialize-only;

AWS_PARAMS="--storageProperty s3.keyId.env.var:AWS_ACCESS_KEY_ID  --storageProperty s3.secret.env.var:AWS_SECRET_ACCESS_KEY"
AZ_PARAMS="--storageProperty az.accountName.env.var:AZURE_ACCOUNT_NAME  --storageProperty az.accountKey.env.var:AZURE_ACCOUNT_KEY"
GCP_CREDENTIAL_PATH="/var/run/secrets/cloud-credentials-cache/gcp-credentials.json"
GCP_PARAMS="--storageProperty gs.credentials.path:${GCP_CREDENTIAL_PATH}"
EXTRA_PARAMS=""


case "$BACKUP_PATH" in
s3://* )
    echo "S3 Bucket detected. Restoring backups from AWS S3"
    EXTRA_PARAMS="${AWS_PARAMS}"
    ;;
az://* )
    echo "Azure Bucket detected. Restoring backups from Azure block storage"
    EXTRA_PARAMS="${AZ_PARAMS}"
    ;;
gs://* )
    EXTRA_PARAMS="${GCP_PARAMS}"
    ;;
*)
    echo "Restoring backups from local storage"
    EXTRA_PARAMS=""
    ;;
esac

echo "Getting list of latest backups and backends. This could take a while..."

# We prune the task backend, schema, user and monitor roots.
BACKEND_NAMES=$( dsbackup list --last --verify --noPropertiesFile --backupLocation ${BACKUP_PATH} ${EXTRA_PARAMS} | \
    grep -i "backend name" |  grep -v 'tasks\|rootUser\|monitorUser\|schema' |  awk '{printf "%s %s ","--backendName", $3}')

if [ ! -z "${BACKEND_NAMES}" ]; then
    echo "Verification completed."
    echo "Restoring backups from: ${BACKUP_PATH}"
    echo "Restoring ${BACKEND_NAMES}"
    dsbackup restore --offline --noPropertiesFile --backupLocation ${BACKUP_PATH} ${EXTRA_PARAMS} ${BACKEND_NAMES}
    echo "Restore operation complete"
else
    echo "No Backups found in ${BACKUP_PATH}. Nothing to restore"
fi

