#!/usr/bin/env bash
# Simple script to schedule DS backups

# Note:
# In order to enable cloud storage in 7.0, the user must update the secret forgeops/kustomize/base/7.0/ds/base/cloud-storage-credentials.yaml with the appropriate credentials. To ahieve this you can run the following commands and replace the content of the file with the output of the command.
# kubectl create secret generic cloud-storage-credentials --from-literal=AWS_ACCESS_KEY_ID=CHANGEME_key --from-literal=AWS_SECRET_ACCESS_KEY=CHANGEME_secret --dry-run -o yaml > ./forgeops/kustomize/base/7.0/ds/base/cloud-storage-credentials.yaml #AWS
# kubectl create secret generic cloud-storage-credentials --from-file=GOOGLE_CREDENTIALS_JSON=CHANGEME_PATH.json --dry-run -o yaml > ./forgeops/kustomize/base/7.0/ds/base/cloud-storage-credentials.yaml #GCP
# kubectl create secret generic cloud-storage-credentials --from-literal=AZURE_ACCOUNT_NAME=CHANGEME_storageAcctName --from-literal=AZURE_ACCOUNT_KEY="CHANGEME_storageAcctKey" --dry-run -o yaml > ./forgeops/kustomize/base/7.0/ds/base/cloud-storage-credentials.yaml #Azure

BACKUP_SCHEDULE="0 * * * *"
kcontext=$(kubectl config current-context)
NS=$(kubectl config view -o jsonpath="{.contexts[?(@.name==\"$kcontext\")].context.namespace}")
if [ $# = '1' ]; then
    NAMESPACE=$1
    BACKUP_DIRECTORY_ENV=""
elif [ $# = '2' ]; then
    echo "WARNING: BACKUP_DIRECTORY is ignored in DS 7.0. If targetting DS 7.0, set DSBACKUP_DIRECTORY in your Kustomize overlay instead"
    NAMESPACE=$1
    BACKUP_DIRECTORY_ENV="BACKUP_DIRECTORY=$2"
else
    echo "usage: $0 NAMESPACE [ /local/path ]"
    echo "example for 6.5: $0 mynamespace /opt/opendj/bak"
    echo "example for 7.0: $0 mynamespace"
    exit -1
fi

if [[ -z "$NAMESPACE" ]] ; then
    echo 'Please provide the target namespace. e.a. schedule-backups.sh namespace-name'
    exit -1
fi

if [[ -z "$BACKUP_DIRECTORY_ENV" ]] ; then
    # 7.0: Only back up the first pod. All pods can restore from the same backup
    pods=($(kubectl -n $NAMESPACE get pods --no-headers=true | echo $(awk '/ds-cts-0|ds-idrepo-0/{print $1}')))
else
    # 6.5: Back up all pods
    pods=($(kubectl -n $NAMESPACE get pods --no-headers=true | echo $(awk '/ds-cts|ds-idrepo/{print $1}')))
fi

# only set $ADMIN_PASSWORD if the secret is available. This information is only used in 7.0.
if [[ $(kubectl -n $NAMESPACE get secret ds-passwords -o jsonpath="{.data.dirmanager\.pw}") ]] &>/dev/null; then
  ADMIN_PASSWORD=$(kubectl -n $NAMESPACE get secret ds-passwords -o jsonpath="{.data.dirmanager\.pw}" | base64 --decode)
fi
for pod in "${pods[@]}"
do
  echo ""
  echo "scheduling backup for pod: $pod"
  kubectl -n $NAMESPACE exec $pod -- bash -c "ADMIN_PASSWORD=${ADMIN_PASSWORD} \
                                              ${BACKUP_DIRECTORY_ENV} \
                                              BACKUP_SCHEDULE='${BACKUP_SCHEDULE}' \
                                              ./scripts/schedule-backup.sh"
done
