import * as pulumi from "@pulumi/pulumi";
import { Config } from "@pulumi/pulumi";

const cluster = new Config("cluster");
const primaryPool = new Config("primarynodes");
const secondaryPool = new Config("secondarynodes");
const dsPool = new Config("dsnodes");
const frontEndPool = new Config("frontendnodes");
const local = new Config("localssdprovisioner");
const gcp = new Config("gcp");

// **************** PROJECT CONFIG ****************
export const project = new pulumi.Config(pulumi.getProject());

// **************** ENABLE RESOURCES ****************
export const enableSecondaryPool = secondaryPool.requireBoolean("enable");
export const enableDSPool = dsPool.requireBoolean("enable");
export const enableFrontEndPool = frontEndPool.requireBoolean("enable");
export const enableLocalSsdProvisioner = local.getBoolean("enable") || false;

// **************** NETWORK CONFIG ****************
export const stackRef = cluster.get("infraStackName") || "gcp-infra"
export const vpcName = cluster.get("vpcName");
export const ip = cluster.requireBoolean("createStaticIp");

// **************** CLUSTER CONFIG ****************
export const clusterName = cluster.require("name");
export const numOfZones = cluster.requireNumber("availabilityZoneCount");
export const k8sVersion = cluster.get("k8sVersion") || "latest";
export const region = gcp.get("region") || "us-east1";
export const disableIstio = cluster.getBoolean("disableIstio") || true;
export const disableHPA = cluster.getBoolean("disableHorizontalPodAutoscaling") || true;
export let namespaces: Array<string> = cluster.getObject("namespaces") || ["prod"];
let user = process.env["USER"] || "unknown";
user = user.toLowerCase();
export const username = user.replace("." , "_");

// **************** LABELS ****************
let backendLabels: {[key: string]: string} = {
    "deployedby": "Pulumi",
    "backend": "true",
    "forgerock.io/role": "backend"
};

let frontendLabels: {[key: string]: string} = {
    "frontend": "true",
    "forgerock.io/role": "frontend"
};

let dsLabels: {[key: string]: string} = {
    "ds": "true",
    "forgerock.io/role": "ds"
};

// Assign additional labels values if set
export const primaryLabels: object = primaryPool.getObject("labels") || {};
export const secondaryLabels: object = secondaryPool.getObject("labels") || {};

// If not deploying ds nodegroup, label backend cluster so ds pods run in backend nodes
if (!enableDSPool){
    backendLabels["ds"] = "true";
}

// If not deploying frontend nodegroup, label backend cluster so ingress controller pods run in backend nodes
if (!enableFrontEndPool){
    backendLabels["frontend"] = "true";
}

// **************** TAINTS ****************
let dsTaints = [
    {
        "key": "WorkerDedicatedDS",
        "value": "true",
        "effect": "NO_SCHEDULE"
    }
]

let frontendTaints = [
    {
        "key": "WorkerDedicatedFrontend",
        "value": "true",
        "effect": "NO_SCHEDULE"
    }
]

// Assign additional taints values if set
export const primaryTaints: object = primaryPool.getObject("taints") || [];
export const secondaryTaints: object = secondaryPool.getObject("taints") || [];


// **************** NODE POOLS ****************
interface NodePool {
    initialNodeCount: number;
    nodeCount: number;
    nodeMachineType: string;
    diskSize: number;
    diskType: string;
    enableAutoScaling: boolean;
    minNodes: number;
    maxNodes: number;
    preemptible: boolean;
    nodePoolName: string;
    labels: object;
    taints: object;
    localSsdCount: number
};

export const stackname = pulumi.getStack();

// PRIMARY NODE POOL VALUES.
export const primary:NodePool = {
    initialNodeCount: primaryPool.getNumber("initialNodeCount") || 1,
    nodeCount: primaryPool.getNumber("nodeCount") || 0,
    nodeMachineType: primaryPool.get("nodeMachineType") || "n1-standard-2",
    diskSize: primaryPool.getNumber("diskSizeGb") || 80,
    diskType: primaryPool.get("diskType") || "pd-ssd",
    enableAutoScaling: primaryPool.requireBoolean("autoScaling"),
    minNodes: primaryPool.getNumber("minNodes") || 2,
    maxNodes: primaryPool.getNumber("maxNodes") || 4,
    preemptible: primaryPool.requireBoolean("preemptible"),
    nodePoolName: primaryPool.get("name") || "primary",
    labels: Object.assign({}, backendLabels, primaryLabels),
    taints: primaryTaints,
    localSsdCount: primaryPool.getNumber("localSsdCount") || 0
};

// SECONDARY NODE POOL VALUES
export const secondary:NodePool = {
    initialNodeCount: secondaryPool.getNumber("initialNodeCount") || 1,
    nodeCount: secondaryPool.getNumber("nodeCount") || 0,
    nodeMachineType: secondaryPool.get("nodeMachineType") || "n1-standard-2",
    diskSize: secondaryPool.getNumber("diskSizeGb") || 80,
    diskType: secondaryPool.get("diskType") || "pd-ssd",
    enableAutoScaling: secondaryPool.getBoolean("autoScaling") || false,
    minNodes: secondaryPool.getNumber("minNodes") || 1,
    maxNodes: secondaryPool.getNumber("maxNodes") || 4,
    preemptible: secondaryPool.getBoolean("preemptible") || false,
    nodePoolName: secondaryPool.get("name") || "secondary",
    labels: Object.assign({}, backendLabels, secondaryLabels),
    taints: secondaryTaints,
    localSsdCount: secondaryPool.getNumber("localSsdCount") || 0
};

// FRONT END NODE POOL VALUES
export const frontend:NodePool = {
    initialNodeCount: frontEndPool.getNumber("initialNodeCount") || 1,
    nodeCount: frontEndPool.getNumber("nodeCount") || 0,
    nodeMachineType: frontEndPool.get("nodeMachineType") || "n1-standard-2",
    diskSize: frontEndPool.getNumber("diskSizeGb") || 80,
    diskType: frontEndPool.get("diskType") || "pd-ssd",
    enableAutoScaling: frontEndPool.getBoolean("autoScaling") || false,
    minNodes: frontEndPool.getNumber("minNodes") || 1,
    maxNodes: frontEndPool.getNumber("maxNodes") || 4,
    preemptible: frontEndPool.getBoolean("preemptible") || false,
    nodePoolName: frontEndPool.get("name") || "frontend",
    labels: Object.assign({}, frontendLabels),
    taints: frontendTaints,
    localSsdCount: frontEndPool.getNumber("localSsdCount") || 0
};

// DS NODE POOL VALUES
export const ds:NodePool = {
    initialNodeCount: dsPool.getNumber("initialNodeCount") || 1,
    nodeCount: dsPool.getNumber("nodeCount") || 0,
    nodeMachineType: dsPool.get("nodeMachineType") || "n1-standard-2",
    diskSize: dsPool.getNumber("diskSizeGb") || 80,
    diskType: dsPool.get("diskType") || "pd-ssd",
    enableAutoScaling: dsPool.getBoolean("autoScaling") || false,
    minNodes: dsPool.getNumber("minNodes") || 1,
    maxNodes: dsPool.getNumber("maxNodes") || 4,
    preemptible: dsPool.getBoolean("preemptible") || false,
    nodePoolName: dsPool.get("name") || "ds",
    labels: Object.assign({}, dsLabels),
    taints: dsTaints,
    localSsdCount: dsPool.getNumber("localSsdCount") || 0
};

// **************** LOCAL SSD VALUES ****************
export const localSsdVersion = local.get("version") || "v2.2.1";
export const localSsdNamespace = local.get("namespace") || "local-storage";


