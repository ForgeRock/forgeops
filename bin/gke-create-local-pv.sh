#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

# TODO: dynamically pick up zones instead of hard coding them
#source "${BASH_SOURCE%/*}/../etc/gke-env.cfg"


kubectl create -f - <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: local-nvme-0
spec:
  capacity:
    storage: 375Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-nvme
  local:
    path: /mnt/disks/ssd0
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: disk
          operator: In
          values:
          - local-nvme
        - key: failure-domain.beta.kubernetes.io/zone
          operator: In
          values:
          - us-east1-d
---

apiVersion: v1
kind: PersistentVolume
metadata:
  name: local-nvme-1
spec:
  capacity:
    storage: 375Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-nvme
  local:
    path: /mnt/disks/ssd0
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: disk
          operator: In
          values:
          - local-nvme
        - key: failure-domain.beta.kubernetes.io/zone
          operator: In
          values:
          - us-east1-c
EOF
