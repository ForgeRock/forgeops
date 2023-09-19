#!/usr/bin/env bash
# Simple script to schedule DS backups

# Creating cloud storage credentials:
# In order to enable cloud storage, the user must update the secret forgeops/kustomize/base/ds/base/cloud-storage-credentials.yaml with the appropriate credentials. 
# To achieve this, you can edit and run the following commands on your command line.
## For AWS deployments, use:
# kubectl create secret generic cloud-storage-credentials --from-literal=AWS_ACCESS_KEY_ID=CHANGEME_key --from-literal=AWS_SECRET_ACCESS_KEY=CHANGEME_secret --dry-run=client -o yaml > ./kustomize/base/ds/base/cloud-storage-credentials.yaml
## For Google Cloud deployments, use:
# kubectl create secret generic cloud-storage-credentials --from-file=GOOGLE_CREDENTIALS_JSON=CHANGEME_PATH.json --dry-run=client -o yaml > ./kustomize/base/ds/base/cloud-storage-credentials.yaml
## For Azure deployments, use:
# kubectl create secret generic cloud-storage-credentials --from-literal=AZURE_STORAGE_ACCOUNT_NAME="CHANGEME_storageAcctName" --from-literal=AZURE_ACCOUNT_KEY="CHANGEME_storageAcctKey" --dry-run=client -o yaml > ./kustomize/base/ds/base/cloud-storage-credentials.yaml


## CONFIGURE DSBACKUP PROPERTIES IN THE SECTION BELOW ONLY
#######################################################################################

# Backup hosts(e.g. ds-idrepo-0,ds-cts-0)
hosts="ds-idrepo-0"

# Directory to store backup list file. `dsbackup list` only
BACKUP_LIST_DIR="/tmp/backupLists"

### IDREPO SCHEDULE ###
BACKUP_SCHEDULE_IDREPO="*/30 * * * *"
TASK_NAME_IDREPO="recurringBackupTask"
# BACKUP_DIRECTORY can be set to either an existing directory on the pod or a pre-existing cloud storage bucket: 
#   Pod:         /local/path
#   Cloud Storage: s3://bucket/path | az://container/path | gs://bucket/path
# Azure path is the container not the storage account which is defined in cloud-storage-credentials
BACKUP_DIRECTORY_IDREPO="/opt/opendj/data/bak"
# Optional backends, default: all backends
# Current enabled backends: amCts,amIdentityStore,cfgStore,idmRepo,monitorUser,proxyUser,rootUser,schema,tasks
BACKENDS_IDREPO=""

### CTS SCHEDULE ###
BACKUP_SCHEDULE_CTS="*/30 * * * *"
TASK_NAME_CTS="recurringBackupTask"
# BACKUP_DIRECTORY can be set to either an existing directory on the pod or a pre-existing cloud storage bucket: 
# Pod:         /local/path
# Cloud Storage: s3://bucket/path | az://container/path | gs://bucket/path
BACKUP_DIRECTORY_CTS="/opt/opendj/data/bak"
# Optional backends, default: all backends
# Current enabled backends: amCts,amIdentityStore,cfgStore,idmRepo,monitorUser,proxyUser,rootUser,schema,tasks
BACKENDS_CTS=""

#######################################################################################

# Check that the correct arguments have been provided
if [ -z "$1" ] || ! [[ $1 =~ ^(create|list|cancel)$ ]]; then
    echo "Usage: $0 [create|list|cancel]"
    exit -1
fi

# Set context
kcontext=$(kubectl config current-context)
NS=$(kubectl config view -o jsonpath="{.contexts[?(@.name==\"$kcontext\")].context.namespace}")

if [ -n "${NS}" ] || [ $# = '1' ]; then
    NAMESPACE="${NS:=$1}"
    # BACKUP_DIRECTORY_ENV=""
else
    echo "usage: $0 [NAMESPACE]"
    echo "example: $0 mynamespace"
    echo "NAMESPACE is optional. NAMESPACE will default to the one set in kubeconfig"
    exit -1
fi

if [[ -z "$NAMESPACE" ]] ; then
    echo "Please provide the target namespace. Example: $0 mynamespace"
    exit -1
fi

# Get DS version
ds_version=$(kubectl -n $NAMESPACE exec ds-idrepo-0 -- /opt/opendj/bin/dsconfig --version)
major_version=$(printf $ds_version| awk -F' ' '{print $1}'| cut -d'.' -f1)
echo "DS server version: ${ds_version}"

# Convert comma separated values to array
pods=($(echo "$hosts" | awk '{split($0,arr,",")} {for (i in arr) {print arr[i]}}'))

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
        TASK_NAME="${TASK_NAME_IDREPO}"
        BACKENDS="${BACKENDS_IDREPO}"
    else
        BACKUP_SCHEDULE="${BACKUP_SCHEDULE_CTS}"
        BACKUP_DIRECTORY="${BACKUP_DIRECTORY_CTS}"
        TASK_NAME="${TASK_NAME_CTS}"
        BACKENDS="${BACKENDS_CTS}"
    fi

    case $1 in 
        create )
            echo "scheduling backup schedule $BACKUP_SCHEDULE for pod: $pod"
            kubectl -n $NAMESPACE exec $pod -- bash -c "BACKUP_SCHEDULE='${BACKUP_SCHEDULE}' \
                                                        TASK_NAME='${TASK_NAME}' \
                                                        BACKUP_DIRECTORY='${BACKUP_DIRECTORY}' \
                                                        BACKENDS='${BACKENDS}' \
                                                        /opt/opendj/default-scripts/schedule-backup.sh"
            ;;
        list )
            echo "Listing backups scheduled on: $pod"
            if BACKUP_LIST=$(kubectl -n $NAMESPACE exec $pod -- bash -c "dsbackup list -d ${BACKUP_DIRECTORY}/${pod}"); then
                 mkdir -p $BACKUP_LIST_DIR/${pod}
                 backupfile="${BACKUP_LIST_DIR}/${pod}/backup-list.$(date "+%Y.%m.%d-%H.%M.%S")"
                 echo $BACKUP_LIST > $backupfile
                 echo -e "Backup saved to ${backupfile}\n\n"
            fi
            ;;
        cancel )
            echo "Cancelling backup schedule: ${TASK_NAME} "
            kubectl -n $NAMESPACE exec $pod -- bash -c "BACKUP_SCHEDULE='${BACKUP_SCHEDULE}' \
                                                        TASK_NAME='${TASK_NAME}' \
                                                        BACKUP_DIRECTORY='${BACKUP_DIRECTORY}' \
                                                        CANCEL=TRUE \
                                                        /opt/opendj/default-scripts/schedule-backup.sh"
            ;;
        *)
          echo "Usage: $0 [create|list|cancel]"
          ;;
    esac   

done

 