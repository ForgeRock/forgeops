import * as pulumi from "@pulumi/pulumi";
import { Config } from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";

const config = new Config();

// ** PROJECT CONFIG **
export const project = new pulumi.Config(pulumi.getProject());

// ** NETWORK CONFIG **
// Add 'eks-cdm:vpc: <vpc>' and 'eks-cdm:subnetIds: <subnetIds>' if you already have a vpc configured. If not, Pulumi will generate one for you.
export const vpc = config.get("vpc");
export let subnetIds = config.getObject<string[]>("subnetIds") || [];
//  Add 'gke-cdm:staticIp <IP name>' if you already have a reserved staticIp. If not, Pulumi will generate 1 for you.
export const ip = config.get<string>("staticIp");
export const route53Domain = config.get<string>("route53Domain");

// ** CLUSTER CONFIG **
export const clusterName = config.require("clusterName");
export const numOfAzs = config.getNumber("numOfAzs") || 2;
export const ami = config.require("ami");
export const k8sVersion = config.get("k8sVersion") || "latest";
export const nginxVersion = config.get("nginxVersion") || "0.25.0";
export const k8sDashboard = config.getBoolean("k8sDashboard") || false;
export const pubKey = config.getSecret("pubKey");

// ** NODE POOL CONFIG **
export const nodeCount = config.getNumber("nodeCount") || 2;
export const cpuPlatform = config.get("cpuPlatform") || "Intel Skylake";
export const machineType = config.get<aws.ec2.InstanceType>("machineType") || "t2.medium";
export const diskSize = config.getNumber("diskSizeGb") || 80;
export const diskType = config.get("diskType") || "pd-ssd";
export let minNodes = config.getNumber("min") || 2;
export let maxNodes = config.getNumber("max") || 4;

// ** ADDITIONAL GCP RESOURCES **
// Please add 'gke-cdm:bucketName <bucketName>' to stack file if you would like a bucket created for DS exports.
export const bucketName = config.get("bucketName");








