#!/usr/bin/env bash

cd /opt/opendj
FULL_CRON="0 0 * * *"
INCREMENTAL_CRON="0 * * * *"

#TODO This is a temporary workaround. taskIds are randmonly generated. see OPENDJ-7141. Need to obtain the name of the task, then cancel it.
echo "Cancelling any previously scheduled backup tasks. Ignore errors if the task does not exist"
TASK_NAME=$(manage-tasks --summary --hostname "${FQDN_DS0}" --port 4444 --bindDN "uid=admin" --bindPassword  "${ADMIN_PASSWORD}" --trustAll | grep -i backuptask -m 1| awk '{print $1;}')
if [ ${TASK_NAME} ]; then 
  echo "Cancelling task: ${TASK_NAME}"
  manage-tasks --cancel "${TASK_NAME}" --hostname "${FQDN_DS0}" --port 4444 --bindDN "uid=admin" --bindPassword  "${ADMIN_PASSWORD}" --trustAll | grep -i backuptask -m 1| awk '{print $1;}'
fi


dsbackup create \
 --hostname "${FQDN_DS0}" \
 --port 4444 \
 --bindDN uid=admin \
 --bindPassword "${ADMIN_PASSWORD}" \
 --backupDirectory "${BACKUP_DIRECTORY}" \
 --encrypt \
 --recurringTask "${INCREMENTAL_CRON}" \
 --trustAll
# --usePkcs12TrustStore /opt/opendj/secrets/keystore \
# --trustStorePasswordFile /opt/opendj/secrets/keystore.pin \


