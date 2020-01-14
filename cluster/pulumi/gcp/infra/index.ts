import * as gcp from "@pulumi/gcp";
import * as pulumi from "@pulumi/pulumi";
import { Config } from "@pulumi/pulumi";
import * as v from "./vpc";

/************* VPC CONFIGURATION *************/

// Fetch VPC config
const vpcConfig = new Config('vpc');

export let vpc: gcp.compute.Network;
export let vpcId: pulumi.Output<string>;
export let subnetId: pulumi.Output<string>;


// Create new VPC if enabled
if (vpcConfig.getBoolean("enable")) {
    vpc = v.createVpc();
    vpcId = vpc.name;
    subnetId = v.createSubnetworks(vpc).selfLink;

    // v.createSubnetworks(vpc);
    // const ip = v.createStaticIp();

    // v.createNetworkLoadbalancer(vpc, ip)
}


/********* GCS BUCKET CONFIGURATION ***********/

// Fetch GCS config
const bucketConfig = new Config('bucket');

// Enable/disable GCS bucket creation
const enableBucket: boolean = bucketConfig.getBoolean("enable") || false;

// Set variables
export let bucketName = bucketConfig.get("name");

// Create GCP bucket if bucket name is provided
if (enableBucket) {
    bucketName = bucketConfig.require("name")
    // Create a GCP resource (Storage Bucket)
    new gcp.storage.Bucket(bucketName);
}
