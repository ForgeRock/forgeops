#!/usr/bin/env bash
# Simple script to schedule DS backups

# Note:
# In order to enable cloud storage in 7.0, the user must update the secret "cloud-storage-credentials" with the appropriate credentials.
# There are 2 ways to achieve this:
# 1) Modify the "cloud-storage-credentials" secret directly before deployment. See forgeops/kustomize/base/7.0/ds/base/cloud-storage-credentials.yaml
# 
# 2) Apply changes to "cloud-storage-credentials-cts" and "cloud-storage-credentials-idrepo" after deployment 
# but before scheduling backup or restore operations :
#   kubectl create secret generic cloud-storage-credentials-[idrepo|cts] --from-literal=AWS_ACCESS_KEY_ID=foobarkey --from-literal=AWS_SECRET_ACCESS_KEY=foobarkeysecret --dry-run -o yaml | kubectl apply -f - #AWS
#   kubectl create secret generic cloud-storage-credentials-[idrepo|cts] --from-file=GOOGLE_CREDENTIALS_JSON=file-from-gcp-2dada2b03f03.json --dry-run -o yaml | kubectl apply -f -  #GCP
#   kubectl create secret generic cloud-storage-credentials-[idrepo|cts] --from-literal=AZURE_ACCOUNT_NAME=storageAcctName --from-literal=AZURE_ACCOUNT_KEY="storageAcctKey" --dry-run -o yaml | kubectl apply -f - 

BACKUP_SCHEDULE="0 * * * *"
kcontext=$(kubectl config current-context)
NS=$(kubectl config view -o jsonpath="{.contexts[?(@.name==\"$kcontext\")].context.namespace}")
if [ $# = '1' ]; then
    NAMESPACE=$1
    BACKUP_DIRECTORY_ENV=""
elif [ $# = '2' ]; then
    # BACKUP_DIRECTORY not required for 7.0. Set DSBACKUP_DIRECTORY in your Kustomize overlay instead.
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

if [[ $BACKUP_DIRECTORY == s3://* || $BACKUP_DIRECTORY == az://* || $BACKUP_DIRECTORY == gs://* ]]; then
    # If we're sending backups to the cloud, only back up the first pod. All pods can restore from the same backup
    pods=($(kubectl -n $NAMESPACE get pods --no-headers=true | echo $(awk '/ds-cts-0|ds-idrepo-0/{print $1}')))
else
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
