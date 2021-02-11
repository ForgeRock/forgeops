#!/usr/bin/env bash
# Utility script to create the service objects that point to a specific pod in each region
# Edit this for your environment. Run it in each cluster for each region:
# ./create-svc.sh us  <-- apply to US primary
# ./create-svc.sh eu <--- apply to EU

POD=ds-idrepo
CLUSTER="${1:-us}"
NUMBER_PODS=3

rm -f "$POD-svc.yaml"

for ((i=0; i < NUMBER_PODS; i++)); do
    echo "$POD-$i"
    cat >> "$POD-svc.yaml" <<EOF
apiVersion: v1
kind: Service
metadata:
  name: $POD-$i-$CLUSTER
spec:
  ports:
    - protocol: TCP
      port: 1389
      name: tcp-ldap
    - protocol: TCP
      port: 1636
      name: tcp-ldaps
    - protocol: TCP
      port: 4444
      name: tcp-admin
    - protocol: TCP
      port: 8989
      name: tcp-replication
    - protocol: TCP
      port: 8080
      name: http
  selector:
    statefulset.kubernetes.io/pod-name: $POD-$i
---
EOF

done
