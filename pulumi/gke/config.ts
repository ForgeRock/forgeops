import * as pulumi from "@pulumi/pulumi";
import { Config } from "@pulumi/pulumi";

const config = new Config();

// ** PROJECT CONFIG **
export const project = new pulumi.Config(pulumi.getProject())

// ** NETWORK CONFIG **
// Add 'gke-cdm:network: <network name>' if you already have a network configured. 
// If not, Pulumi will generate one for you.
export const network = config.get("network");
//  Add 'gke-cdm:staticIp <IP name>' if you already have a reserved a staticIp. 
// If not, Pulumi will generate 1 for you.
export const ip = config.get<string>("staticIp") || undefined;

// ** CLUSTER CONFIG **
export const clusterName = config.require("clusterName");
// Add 'gke-cdm:enablePreemptible: true' to use Preemptible nodes.
export const enablePreemptible = config.getBoolean("enablePreemptible") || false;
export const nodeZones = config.requireObject<string[]>("nodeZones");
export const k8sVersion = config.get("k8sVersion") || "latest";

// ** NODE POOL CONFIG **
export const nodeCount = config.getNumber("initialNodeCount") || 2;
export const cpuPlatform = config.get("cpuPlatform") || "Intel Skylake";
export const nodeMachineType = config.get("nodeMachineType") || "n1-standard-2";
export const diskSize = config.getNumber("diskSizeGb") || 80;
export const diskType = config.getNumber("diskType") || "pd-ssd";
export let minNodes = config.getNumber("min") || 2;
export let maxNodes = config.getNumber("max") || 4;

// ** ADDITIONAL GCP RESOURCES **
// Please add 'gke-cdm:bucketName <bucketName>' to stack file if you would like a bucket created for DS exports.
export const bucketName= config.get("bucketName")








