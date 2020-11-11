#!/usr/bin/env bash
# Simple script to schedule DS backups

# Note:
# In order to enable cloud storage in 7.0, the user must update the secret forgeops/kustomize/base/7.0/ds/base/cloud-storage-credentials.yaml with the appropriate credentials. To ahieve this you can run the following commands.
# kubectl create secret generic cloud-storage-credentials --from-literal=AWS_ACCESS_KEY_ID=CHANGEME_key --from-literal=AWS_SECRET_ACCESS_KEY=CHANGEME_secret --dry-run -o yaml > ./forgeops/kustomize/base/7.0/ds/base/cloud-storage-credentials.yaml #AWS
# kubectl create secret generic cloud-storage-credentials --from-file=GOOGLE_CREDENTIALS_JSON=CHANGEME_PATH.json --dry-run -o yaml > ./forgeops/kustomize/base/7.0/ds/base/cloud-storage-credentials.yaml #GCP
# kubectl create secret generic cloud-storage-credentials --from-literal=AZURE_ACCOUNT_NAME=CHANGEME_storageAcctName --from-literal=AZURE_ACCOUNT_KEY="CHANGEME_storageAcctKey" --dry-run -o yaml > ./forgeops/kustomize/base/7.0/ds/base/cloud-storage-credentials.yaml #Azure

BACKUP_SCHEDULE_IDREPO="0 * * * *"
BACKUP_SCHEDULE_CTS="10 * * * *"
kcontext=$(kubectl config current-context)
NS=$(kubectl config view -o jsonpath="{.contexts[?(@.name==\"$kcontext\")].context.namespace}")

if [ -n "${NS}" ] || [ $# = '1' ]; then
    NAMESPACE="${NS:=$1}"
    BACKUP_DIRECTORY_ENV=""

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

ds_version=$(kubectl -n $NAMESPACE exec ds-idrepo-0 -- /opt/opendj/bin/dsconfig --version)
major_version=$(printf $ds_version| awk -F' ' '{print $1}'| cut -d'.' -f1)
echo "DS server version: ${ds_version}"

# Only back up the pods in $DSBACKUP_HOSTS. All pods can restore from the same backup
# hosts=$(kubectl -n $NAMESPACE get statefulset ds-idrepo -o jsonpath='{.spec.template.spec.initContainers[?(@.name=="initialize")].env[?(@.name=="DSBACKUP_HOSTS")].value}')
hosts=$(kubectl -n $NAMESPACE get configmap platform-config -o jsonpath='{.data.DSBACKUP_HOSTS}')
# Convert comma separated values to array
pods=($(echo "$hosts" | awk '{split($0,arr,",")} {for (i in arr) {print arr[i]}}'))

if [ -z "${pods}" ]; then
    echo "No DS hosts provided. No backups were scheduled."
    exit -1
fi
echo "Targeting pods: ${pods[@]}"

# only set $ADMIN_PASSWORD if the secret is available. This information is only used in 7.0.
if [[ $(kubectl -n $NAMESPACE get secret ds-passwords -o jsonpath="{.data.dirmanager\.pw}") ]] &>/dev/null; then
  ADMIN_PASSWORD=$(kubectl -n $NAMESPACE get secret ds-passwords -o jsonpath="{.data.dirmanager\.pw}" | base64 --decode)
fi
for pod in "${pods[@]}"
do
  if [[ "${pod}" = "ds-idrepo"* ]]; then
    BACKUP_SCHEDULE="${BACKUP_SCHEDULE_IDREPO}"
  else
    BACKUP_SCHEDULE="${BACKUP_SCHEDULE_CTS}"
  fi
  echo ""
  echo "scheduling backup schedule $BACKUP_SCHEDULE for pod: $pod"
  kubectl -n $NAMESPACE exec $pod -- bash -c "ADMIN_PASSWORD=${ADMIN_PASSWORD} \
                                              ${BACKUP_DIRECTORY_ENV} \
                                              BACKUP_SCHEDULE='${BACKUP_SCHEDULE}' \
                                              ./scripts/schedule-backup.sh"
done
