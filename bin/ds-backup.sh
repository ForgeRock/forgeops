#!/usr/bin/env bash
# Simple script to schedule DS backups

# Creating cloud storage credentials:
# In order to enable cloud storage, the user must create a secret with the appropriate credentials. 
# To achieve this, you can edit and run the following commands on your command line.
## For AWS deployments, use:
# kubectl create secret generic cloud-storage-credentials --from-literal=AWS_ACCESS_KEY_ID=CHANGEME_key --from-literal=AWS_SECRET_ACCESS_KEY=CHANGEME_secret
## For Google Cloud deployments, use:
# kubectl create secret generic cloud-storage-credentials --from-file=GOOGLE_CREDENTIALS_JSON=CHANGEME_PATH.json
## For Azure deployments, use:
# kubectl create secret generic cloud-storage-credentials --from-literal=AZURE_STORAGE_ACCOUNT_NAME="CHANGEME_storageAcctName" --from-literal=AZURE_ACCOUNT_KEY="CHANGEME_storageAcctKey" --dry-run=client -o yaml > ./kustomize/base/ds/base/cloud-storage-credentials.yaml
## Note : You may want to run the command above before running "forgeops install" or restart the ds pods to pick up the updated secret if the ds pods are already running.

## CONFIGURE DSBACKUP PROPERTIES IN THE SECTION BELOW ONLY
#######################################################################################

# HOSTS
#  - CTS    : consists of loadbalanced pods so use any available pod for backups. (e.g HOSTS="ds-cts-0" or HOSTS="ds-idrepo-2,ds-cts-0")
#  - IDREPO : ds-idrepo-0 is the primary server so use the largest available pod for backups as it won't impact live traffic. (e.g HOSTS="ds-idrepo-2" or HOSTS="ds-idrepo-2,ds-cts-0")
#  - CDK    : only one ds-idrepo pod (HOSTS="ds-idrepo-0")
HOSTS="ds-idrepo-2"

### IDREPO SCHEDULE ###
# Cron schedule for backup task to run
BACKUP_SCHEDULE_IDREPO="*/30 * * * *"
# BACKUP_DIRECTORY can be set to either an existing directory on the pod or a pre-existing cloud storage bucket: 
#   Pod:         /local/path
#   Cloud Storage: s3://bucket/path | az://container/path | gs://bucket/path
BACKUP_DIRECTORY_IDREPO=""
# Backends to backup.
BACKENDS_IDREPO="amIdentityStore,cfgStore,idmRepo"
# Name of task on DS pod. Change if configuring multiple backup schedules.
TASK_NAME_IDREPO="recurringBackupTask"

### CTS SCHEDULE ###
# Cron schedule for backup task to run
BACKUP_SCHEDULE_CTS="*/30 * * * *"
# BACKUP_DIRECTORY can be set to either an existing directory on the pod or a pre-existing cloud storage bucket: 
# Pod:         /local/path
# Cloud Storage: s3://bucket/path | az://container/path | gs://bucket/path
BACKUP_DIRECTORY_CTS=""
# Backend to backup
BACKENDS_CTS="amCts"
# Name of task on DS pod. Change if configuring multiple backup schedules.
TASK_NAME_CTS="recurringBackupTask"

#######################################################################################

# Check that the correct arguments have been provided
if [ -z "$1" ] || ! [[ $1 =~ ^(create|cancel)$ ]]; then
    echo "Usage: $0 [create|cancel]"
    exit 0
fi

# Get DS version
ds_version=$(kubectl exec ds-idrepo-0 -- /opt/opendj/bin/dsconfig --version)
major_version=$(printf $ds_version| awk -F' ' '{print $1}'| cut -d'.' -f1)
echo "DS server version: ${ds_version}"

# Convert comma separated values to array
pods=($(echo "$HOSTS" | awk '{split($0,arr,",")} {for (i in arr) {print arr[i]}}'))

if [ -z "${pods}" ]; then
    echo "No DS hosts provided. No backups were scheduled."
    exit -1
fi
echo "Targeting pods: ${pods[@]}"

# Loop through pods and carry out dsbackup task
for pod in "${pods[@]}"
do
    if [[ "${pod}" = "ds-idrepo"* ]]; then
        BACKUP_SCHEDULE="${BACKUP_SCHEDULE_IDREPO}"
        BACKUP_DIRECTORY="${BACKUP_DIRECTORY_IDREPO}"
        if [[ -z $BACKUP_DIRECTORY ]]; then
            echo "Please provide value for BACKUP_DIRECTORY_IDREPO"
            exit 1
        fi 
        TASK_NAME="${TASK_NAME_IDREPO}"
        BACKENDS="${BACKENDS_IDREPO}"
    else
        BACKUP_SCHEDULE="${BACKUP_SCHEDULE_CTS}"
        BACKUP_DIRECTORY="${BACKUP_DIRECTORY_CTS}"
        if [[ -z $BACKUP_DIRECTORY ]]; then
            echo "Please provide value for BACKUP_DIRECTORY_CTS"
            exit 1
        fi 
        TASK_NAME="${TASK_NAME_CTS}"
        BACKENDS="${BACKENDS_CTS}"
    fi

    case $1 in 
        create )
            echo "scheduling backup schedule $BACKUP_SCHEDULE for pod: $pod"
            kubectl exec $pod -- bash -c "BACKUP_SCHEDULE='${BACKUP_SCHEDULE}' \
                                                        TASK_NAME='${TASK_NAME}' \
                                                        BACKUP_DIRECTORY='${BACKUP_DIRECTORY}' \
                                                        BACKENDS='${BACKENDS}' \
                                                        /opt/opendj/default-scripts/schedule-backup.sh"
            ;;
        cancel )
            echo "Cancelling backup schedule: ${TASK_NAME} "
            kubectl exec $pod -- bash -c "BACKUP_SCHEDULE='${BACKUP_SCHEDULE}' \
                                                        TASK_NAME='${TASK_NAME}' \
                                                        BACKUP_DIRECTORY='${BACKUP_DIRECTORY}' \
                                                        CANCEL=TRUE \
                                                        /opt/opendj/default-scripts/schedule-backup.sh"
            ;;
        *)
          echo "Usage: $0 [create|cancel]"
          ;;
    esac   

done

 