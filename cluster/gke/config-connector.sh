#!/usr/bin/env bash
# This configures service accounts and IAM permissions for the Google Config Connector
# https://cloud.google.com/config-connector/docs/overview
# This is an advanced use case, and this script is not supported by ForgeRock. It is provided
# as a sample only.
#
#
# This assumes the ConfigConnector and Workload Identity addons have been enabled on your cluster
# https://cloud.google.com/config-connector/docs/how-to/install-upgrade-uninstall#project


PROJECT_ID=$(gcloud config list --format 'value(core.project)')

# GSA is the google service account that the *pods* will use to access Google Cloud Platform.
GSA="prod-gsa"
GSA_FULL="${GSA}@${PROJECT_ID}.iam.gserviceaccount.com"

# Kubernetes service accounts. These get mapped to GSA accounts for workload identity
KSA=prod-ksa
K8S_NAMESPACE=prod

# Ensures one ConfigConnector per cluster
kubectl create -f - <<EOF
# configconnector.yaml
apiVersion: core.cnrm.cloud.google.com/v1beta1
kind: ConfigConnector
metadata:
  # the name is restricted to ensure that there is only ConfigConnector instance installed in your cluster
  name: configconnector.core.cnrm.cloud.google.com
EOF

kubectl create ns "$K8S_NAMESPACE" || true
# Creates the Kubernetes service account used for workload identity
kubectl create serviceaccount --namespace "$K8S_NAMESPACE" "$KSA"

# create the google service account that cnrm will use
gcloud iam service-accounts create "$GSA" --display-name="${GSA}"

# Give it project owner access.
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${GSA_FULL}" \
  --role="roles/owner"

# Create a ConfigConnectorContext
kubectl apply -f - <<EOF
# configconnectorcontext.yaml
apiVersion: core.cnrm.cloud.google.com/v1beta1
kind: ConfigConnectorContext
metadata:
  # you can only have one ConfigConnectorContext per Namespace
  name: configconnectorcontext.core.cnrm.cloud.google.com
  namespace: "$K8S_NAMESPACE"
spec:
  # The Google Service Account used to authenticate Google Cloud APIs in this Namespace
  googleServiceAccount: "$GSA_FULL"
EOF

# Verify that the Config Connector Operator created a Kubernetes service account for your namespace
kubectl get "serviceaccount/cnrm-controller-manager-${K8S_NAMESPACE}" -n cnrm-system

# Verify that the Config Connector controller Pod is running for your namespace with kubectl
kubectl wait -n cnrm-system  --for=condition=Ready pod \
  -l cnrm.cloud.google.com/component=cnrm-controller-manager,cnrm.cloud.google.com/scoped-namespace="${K8S_NAMESPACE}"

# Bind your ConfigConnector Kubernetes Service Account to Google Service Account
gcloud iam service-accounts add-iam-policy-binding \
  "${GSA_FULL}" \
  --member="serviceAccount:${PROJECT_ID}.svc.id.goog[cnrm-system/cnrm-controller-manager-${K8S_NAMESPACE}]" \
  --role="roles/iam.workloadIdentityUser"

# Specify where to create resources (project, folder or organization). We use project
kubectl annotate namespace "$K8S_NAMESPACE" cnrm.cloud.google.com/project-id="$PROJECT_ID"

# Verify installation
kubectl wait -n cnrm-system --for=condition=Ready pod --all

# Example of provisioning a resource

# Enables the storage api if not enabled already
kubectl apply -f - <<EOF
apiVersion: serviceusage.cnrm.cloud.google.com/v1beta1
kind: Service
metadata:
  name: storage.googleapis.com
EOF

# See gcp-bucket.yaml for a sample resource


