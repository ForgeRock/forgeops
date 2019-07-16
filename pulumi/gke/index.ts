import * as k8s from "@pulumi/kubernetes";
import * as gcp from "@pulumi/gcp";
import { clusterProvider, k8sConfig } from "./cluster";
import "./nginx-controller";
import { lbIp } from "./nginx-controller";
import "./cert-manager";
//import "./prometheus";
import {
    bucketName,
} from "./config"

// Create GCP bucket if bucket name is provided
if (bucketName !== undefined) {
    // Create a GCP resource (Storage Bucket)
    new gcp.storage.Bucket(<string>bucketName);
}

/********** Create Storage Classes **********/
const efsStorageClass = new k8s.storage.v1.StorageClass("sc-fast", {
    metadata: { name: 'fast' },
    provisioner: 'kubernetes.io/gce-pd',
    parameters: { type: 'pd-ssd' },
}, { provider: clusterProvider } );

const fastStorageClass = new k8s.storage.v1.StorageClass("sc-local-nvme", {
    metadata: { name: 'local-nvme' },
    provisioner: 'kubernetes.io/no-provisioner',
    volumeBindingMode: 'WaitForFirstConsumer',
}, { provider: clusterProvider } );

const nsprod = new k8s.core.v1.Namespace("prod", { metadata: { name: "prod" }}, { provider: clusterProvider });

// Export the Kubeconfig so that clients can easily access our cluster.
export const kubeconfig = k8sConfig;
export const loadbalancerIp = lbIp;



