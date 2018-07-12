#!/usr/bin/env bash
# Create a filstore for shared nfs. Currentnly only used for ds backup and restore.
# See https://rimusz.net/how-to-use-google-cloud-filestore-with-gke/

# Note the minimum size that you can requet is 1TB . About $200 / month.
gcloud beta filestore instances create nfs \
  --location=us-central1-c --tier=STANDARD \
  --file-share=name="vol1",capacity=1TB \
  --network=name="default",reserved-ip-range="10.0.0.0/29"

# Save the IP address of the nfs server from above
# Replace with stable/nfs-client-provisioner. See https://github.com/kubernetes/charts/pull/6433/files
helm repo add rimusz https://helm-charts.rimusz.net
helm repo up


helm install --name nfs-us-central1-c rimusz/nfs-client-provisioner --namespace nfs-storage \
  --set nfs.server="10.0.0.2" --dry-run --debug