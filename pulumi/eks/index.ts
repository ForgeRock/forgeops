import * as k8s from "@pulumi/kubernetes";
import * as aws from "@pulumi/aws";
import { cluster } from "./cluster";
import { vpc } from "./vpc";
import { bucketName } from "./config";
//import "./nginx-controller";
//import "./cert-manager"

/************** S3 BUCKET **************/
// initialize bucket variable
let bucket: aws.s3.Bucket;

// Create an S3 Bucket if bucket name supplied in stack config file.
if (bucketName !== undefined) {
    // create bucket
    bucket = new aws.s3.Bucket(bucketName, {
        bucket: bucketName,
        forceDestroy: true,
        versioning: {
            enabled: true
        }
    });

    //restrict bucket public access
    new aws.s3.BucketPublicAccessBlock("blockPublicAccess", {
        blockPublicAcls: true,
        blockPublicPolicy: true,
        restrictPublicBuckets: true,
        ignorePublicAcls: true,
        bucket: bucket.id,
    });
}

/************** K8S NAMESPACES **************/
new k8s.core.v1.Namespace("prod", { metadata: { name: "prod" }}, { provider: cluster.provider });
new k8s.core.v1.Namespace("monitoring", { metadata: { name: "monitoring" }}, { provider: cluster.provider });

/************** STORAGE CLASSES **************/
// Create fast gp2 storage class
new k8s.storage.v1.StorageClass("fast", {
    metadata: { name: 'fast' },
    provisioner: 'kubernetes.io/aws-ebs',
    parameters: { type: 'gp2' },
}, { provider: cluster.provider } );

// Create fast io1 storage class
new k8s.storage.v1.StorageClass("fast10", {
    metadata: { name: 'fast10' },
    provisioner: 'kubernetes.io/aws-ebs',
    parameters: { type: 'io1', fstype: 'ext4', iopsPerGB: '10' },
}, { provider: cluster.provider } );

/************** OUTPUTS **************/

// Export the clusters' kubeconfig.
export const kubeconfig = cluster.kubeconfig;

// Export VPC id
export const vpcId = vpc.id;
