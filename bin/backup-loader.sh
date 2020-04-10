#!/usr/bin/env bash
set -o errexit -o pipefail

usage() {
    echo " This script allows users to preload the backup PVCs used by ds-cts and ds-idrepo with local data"
    echo "Usage: $0 [options]" >&2
    echo
    echo "   -h   Displays this message"
    echo "   -n   Set target namespace"
    echo "   -r   Set the number of PVCs to create (replicas). Default 1"
    echo "   -s   Set the CTS disk size. Default 10Gi"
    echo "   -z   Set the IDREPO disk size. Default 10Gi"
    echo "   -b   Set the source path for CTS"
    echo "   -u   Set the source path for IDREPO"
    echo
    # echo some stuff here for the -a or --add-options 
}

NAMESPACE="default"
REPLICAS="1"
CTS_DISK_SIZE="10Gi"
IDREPO_DISK_SIZE="10Gi"
#CTS_BACKUP_PATH=No default path set
#IDREPO_BACKUP_PATH= No default path set
CREATE_PVCS=true

# handle opts
while getopts n:r:s:z:b:u:p:h option
do
    case "${option}"
        in
        n) NAMESPACE=${OPTARG};;
        r) REPLICAS=${OPTARG};;
        s) CTS_DISK_SIZE=${OPTARG};;
        z) IDREPO_DISK_SIZE=${OPTARG};;
        b) CTS_BACKUP_PATH=${OPTARG};;
        u) IDREPO_BACKUP_PATH=${OPTARG};;
        p) CREATE_PVCS=${OPTARG};;
        h) usage; exit 0;;
        *) usage; exit 1;;
    esac
done

if [ -z ${CTS_BACKUP_PATH+x} ] && [ -z ${IDREPO_BACKUP_PATH+x} ]; then echo "Must specify at least one backup source path using -b or -u"; usage; exit 1; fi


echo "NAMESPACE=$NAMESPACE"
echo "REPLICAS=$REPLICAS"
echo "CTS_DISK_SIZE=$CTS_DISK_SIZE"
echo "IDREPO_DISK_SIZE=$IDREPO_DISK_SIZE"
echo "CTS_BACKUP_PATH=$CTS_BACKUP_PATH"
echo "IDREPO_BACKUP_PATH=$IDREPO_BACKUP_PATH"
echo "CREATE_PVCS=$CREATE_PVCS"

STATEFULSET=$(cat <<EOF
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: ds-name
spec:
  selector:
    matchLabels:
      app: ds-name
  serviceName: ds-name
  replicas: 1
  template:
    metadata:
      labels: 
        app: ds-name
      annotations:
        sidecar.istio.io/inject: "false"
    spec:
      tolerations:
      - key: "WorkerDedicatedDS"
        operator: "Exists"
      containers:
        - name: loader
          image: busybox
          command: ["ash", "-c", "--"]
          args: [ "while true; do sleep 10; done;" ]
          volumeMounts:
          - name: backup
            mountPath: /bak
  volumeClaimTemplates:
  - metadata:
      name: backup
      annotations:
        pv.beta.kubernetes.io/gid: "0"
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 10Gi
EOF
)


if $CREATE_PVCS;
then
  echo "*** Creating placeholder statefulsets for ds-cts and ds-idrepo"
  if [ "$CTS_BACKUP_PATH" ];
  then
    echo "$STATEFULSET" | sed "s/ds-name/ds-cts/;    s/replicas:.*/replicas: $REPLICAS/; s/storage:.*/storage: $CTS_DISK_SIZE/"    | kubectl --namespace=$NAMESPACE create -f -
  fi
  
  if [ "$IDREPO_BACKUP_PATH" ];
  then
    echo "$STATEFULSET" | sed "s/ds-name/ds-idrepo/; s/replicas:.*/replicas: $REPLICAS/; s/storage:.*/storage: $IDREPO_DISK_SIZE/" | kubectl --namespace=$NAMESPACE create -f -
  fi

  echo "Sleeping 15 secs before checking pod status..."
  sleep 15
  if [ "$CTS_BACKUP_PATH"    ]; then kubectl --namespace=$NAMESPACE wait --for=condition=Ready pod -l app=ds-cts;    fi
  if [ "$IDREPO_BACKUP_PATH" ]; then kubectl --namespace=$NAMESPACE wait --for=condition=Ready pod -l app=ds-idrepo; fi
else
  echo "PVCs won't be created. Assuming you already have these created"
fi

if [ "$CTS_BACKUP_PATH" ];
then
  echo ""
  echo "*** Starting kubectl cp for ds-cts"
  for podname in $(kubectl --namespace=$NAMESPACE get pods -l app=ds-cts -o json| jq -r '.items[].metadata.name') 
  do 
    echo "copying backup files from $CTS_BACKUP_PATH to $podname"
    for file in ${CTS_BACKUP_PATH}/*; do
      kubectl --namespace=$NAMESPACE cp $file "${podname}":/bak/
    done
      kubectl --namespace=$NAMESPACE exec -i "${podname}" -- chown -R 11111:root /bak/
  done
fi

if [ "$IDREPO_BACKUP_PATH" ];
then
  echo ""
  echo "*** Starting kubectl cp for ds-idrepo"
  for podname in $(kubectl --namespace=$NAMESPACE get pods -l app=ds-idrepo -o json| jq -r '.items[].metadata.name') 
  do 
    echo "copying backup files from $IDREPO_BACKUP_PATH to $podname"
    for file in ${IDREPO_BACKUP_PATH}/*; do
      kubectl --namespace=$NAMESPACE  cp $file "${podname}":/bak/
    done
      kubectl --namespace=$NAMESPACE exec -i "${podname}" -- chown -R 11111:root /bak/
  done
fi

if $CREATE_PVCS;
then
  echo ""
  echo "*** Cleaning up statefulsets"
  if [ "$CTS_BACKUP_PATH"    ]; then kubectl --namespace=$NAMESPACE delete statefulset ds-cts;    fi
  if [ "$IDREPO_BACKUP_PATH" ]; then kubectl --namespace=$NAMESPACE delete statefulset ds-idrepo; fi
fi

echo ""
echo "*** Done"

