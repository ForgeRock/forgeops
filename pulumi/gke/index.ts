import * as k8s from "@pulumi/kubernetes";
import * as gcp from "@pulumi/gcp";
import * as cluster from "./cluster";
import "./cert-manager";
import * as nginx from "./nginx-controller";
//import "./prometheus";
import * as config from "./config";

// Create GCP bucket if bucket name is provided
if (config.bucketName !== undefined) {
    // Create a GCP resource (Storage Bucket)
    new gcp.storage.Bucket(<string>config.bucketName);
}

/********** Create Storage Classes **********/
new k8s.storage.v1.StorageClass("sc-fast", {
    metadata: { name: 'fast' },
    provisioner: 'kubernetes.io/gce-pd',
    parameters: { type: 'pd-ssd' },
}, { provider: cluster.clusterProvider } );

new k8s.storage.v1.StorageClass("sc-local-nvme", {
    metadata: { name: 'local-nvme' },
    provisioner: 'kubernetes.io/no-provisioner',
    volumeBindingMode: 'WaitForFirstConsumer',
}, { provider: cluster.clusterProvider } );

new k8s.core.v1.Namespace("prod", { metadata: { name: "prod" }}, { provider: cluster.clusterProvider });

// Export the Kubeconfig so that clients can easily access our cluster.
export const kubeconfig = cluster.k8sConfig;
export const loadbalancerIp = nginx.lbIp;



