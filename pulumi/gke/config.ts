import * as pulumi from "@pulumi/pulumi";
import { Config } from "@pulumi/pulumi";

const config = new Config();

// Project config
export const project = new pulumi.Config(pulumi.getProject())
//export const region = config.get("region") || "us-east1";

// Network config
export const network = config.get("network");
export const ip = config.get<string>("staticIp") || undefined;

// Cluster config
export const clusterName = config.require("clusterName");
export const enablePreemptible = config.getBoolean("enablePreemptible") || false;
export const nodeZones = config.getObject<string[]>("nodeZones");
export const k8sVersion = config.get("k8sVersion") || "latest";

// Node Pool config
export const nodeCount = config.getNumber("initialNodeCount") || 2;
export const cpuPlatform = config.get("cpuPlatform") || "Intel Skylake";
export const nodeMachineType = config.get("nodeMachineType") || "n1-standard-2";
export const diskSize = config.getNumber("diskSizeGb") || 80;
export const diskType = config.getNumber("diskType") || "pd-ssd";
export const minNodes = config.getNumber("minNodes") || 1;
export const maxNodes = config.getNumber("maxNodes") || 4;

// Additional GCP resources
export const bucketName= config.get("bucketName")








