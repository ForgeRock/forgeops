#!/usr/bin/env bash
# Sample script to create an autopilot cluster on GKE. Adjust for your environment.

project=$(gcloud config list --format 'value(core.project)') 2>/dev/null

CLUSTER_NAME=${CLUSTER_NAME:-autopilot-test}

# You will need to set the network for your environment:
gcloud beta container --project $project clusters create-auto "$CLUSTER_NAME" \
    --region "us-west4" --release-channel "regular" \
    --network "projects/engineering-devops/global/networks/forgeops" \
    --subnetwork "projects/engineering-devops/regions/us-west4/subnetworks/forgeops" \
    --cluster-ipv4-cidr "/17" --services-ipv4-cidr "/22"


# Create the volume snapshot class used in the samples.
kubectl apply -f - <<EOF
apiVersion: snapshot.storage.k8s.io/v1beta1
kind: VolumeSnapshotClass
metadata:
  name: ds-snapshot-class
driver: pd.csi.storage.gke.io
deletionPolicy: Delete
EOF

kubectl create -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast
parameters:
  type: pd-ssd
provisioner: pd.csi.storage.gke.io
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
EOF

helm repo add jetstack https://charts.jetstack.io
helm repo update

# Install CRDs
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.6.1/cert-manager.crds.yaml

# Set the minumum resource limits (these work for GKE autopilot clusters)
cat >/tmp/cert-manager-values.yaml <<EOF
global:
  leaderElection:
    # Need for GKE autopilot as the kube-system namespace is locked down
    namespace: cert-manager
resources:
  requests:
    cpu: "250m"
    memory: "512Mi"
cainjector:
  resources:
    requests:
      cpu: "250m"
      memory: "512Mi"
webhook:
  resources:
    requests:
      cpu: "250m"
      memory: "512Mi"
EOF

helm install \
    cert-manager jetstack/cert-manager \
    --namespace cert-manager \
    --create-namespace \
    --version v1.6.1 \
    --values /tmp/cert-manager-values.yaml


# Install a self signed cluster issuer
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: default-issuer
spec:
  selfSigned: {}
EOF