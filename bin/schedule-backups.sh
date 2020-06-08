#!/usr/bin/env bash
# Simple script to schedule DS backups

# Note:
# In order to enable cloud storage in 7.0, the user must create a secret as follows:
# kubectl create secret generic cloud-credentials --from-literal=AWS_ACCESS_KEY_ID=foobarkey --from-literal=AWS_SECRET_ACCESS_KEY=foobarkeysecret #AWS
# kubectl create secret generic cloud-credentials --from-file=GOOGLE_CREDENTIALS_JSON=file-from-gcp-2dada2b03f03.json #GCP
# kubectl create secret generic cloud-credentials --from-literal=AZURE_ACCOUNT_NAME=storageAcctName --from-literal=AZURE_ACCOUNT_KEY="storageAcctKey"

kcontext=$(kubectl config current-context)
NS=$(kubectl config view -o jsonpath="{.contexts[?(@.name==\"$kcontext\")].context.namespace}")
if [ $# = '2' ]; then
    NAMESPACE=$1
    BACKUP_DIRECTORY=$2
else
    echo "usage: $0 NAMESPACE [ local_path | s3://bucket/path | az://bucket/path | gs://bucket/path ]"
    echo "example using local_path: $0 mynamespace /opt/opendj/bak"
    echo "example using s3: $0 mynamespace s3://my_bucket_name/path"
    echo "example using gs: $0 mynamespace gs://my_bucket_name/path"
    exit -1
fi

if [[ -z "$NAMESPACE" ]] ; then
    echo 'Please provide the target namespace. e.a. schedule-backups.sh namespace-name'
    exit -1
fi

pods=($(kubectl -n $NAMESPACE get pods --no-headers=true | echo $(awk '/ds-cts|ds-idrepo/{print $1}')))

# only set $ADMIN_PASSWORD if the secret is available. This information is only used in 7.0.
if [[ $(kubectl -n $NAMESPACE get secret ds-passwords -o jsonpath="{.data.dirmanager\.pw}") ]] &>/dev/null; then
  ADMIN_PASSWORD=$(kubectl -n $NAMESPACE get secret ds-passwords -o jsonpath="{.data.dirmanager\.pw}" | base64 --decode)
fi
for pod in "${pods[@]}"
do
  if [[ $BACKUP_DIRECTORY == s3://* || $BACKUP_DIRECTORY == az://* || $BACKUP_DIRECTORY == gs://* ]]; then
    BACKUP_LOCATION="$BACKUP_DIRECTORY/$pod/"
  else
    BACKUP_LOCATION="$BACKUP_DIRECTORY"
  fi
  echo ""
  echo "scheduling backup for pod: $pod"
  kubectl -n $NAMESPACE exec $pod -- bash -c "ADMIN_PASSWORD=$ADMIN_PASSWORD BACKUP_DIRECTORY=$BACKUP_LOCATION ./scripts/schedule-backup.sh"
done
