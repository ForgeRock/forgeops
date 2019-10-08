import * as pulumi from "@pulumi/pulumi";
import { Config } from "@pulumi/pulumi";

const cluster = new Config("cluster");
const nginx = new Config("nginx");
const primaryPool = new Config("primary");
const secondaryPool = new Config("secondary");
const cm = new Config("certmanager");
const dsPool = new Config("ds");

// ** PROJECT CONFIG **
export const project = new pulumi.Config(pulumi.getProject());

// ** ENABLE RESOURCES
export const enableSecondaryPool = secondaryPool.requireBoolean("enable");
export const enableDSPool = dsPool.requireBoolean("enable");
export const enableNginxIngress = nginx.requireBoolean("enable");
export const enableCertManager = cm.requireBoolean("enable");

// ** NETWORK CONFIG **
export const stackRef = cluster.get("infraStackName") || "gke-infra"
export const vpcName = cluster.get("vpcName");
export const ip = cluster.get<string>("staticIp") || undefined;

// ** CLUSTER CONFIG **
export const clusterName = cluster.require("name");
export const nodeZones = cluster.requireObject<string[]>("nodeZones");
export const k8sVersion = cluster.get("k8sVersion") || "latest";
export const nginxVersion = nginx.require("version");
export const disableIstio = cluster.getBoolean("disableIstio") || true;
export const disableHPA = cluster.getBoolean("disableHorizontalPodAutoscaling") || true;
export let namespaces: Array<string> = cluster.getObject("namespaces") || ["prod"];
let user = process.env["USER"] || "unknown";
user = user.toLowerCase();
export const username = user.replace("." , "_");

// NODE POOL
interface NodePool {
    initialNodeCount: number;
    nodeCount: number;
    cpuPlatform: string;
    nodeMachineType: string;
    diskSize: number;
    diskType: string;
    enableAutoScaling: boolean;
    minNodes: number;
    maxNodes: number;
    preemptible: boolean;
    nodePoolName: string;
    labels: object;
    taints?: object;
};

let backendLabels: {[key: string]: string} = {
    "deployedby": "Pulumi",
    "frontend": "true",
    "backend": "true",
    "kubernetes.io/role": "backend"
};

// If not deploying ds nodegroup, label backend cluster so ds pods run in backend nodes
if (!enableDSPool){
    backendLabels["ds"] = "true";
}

// If not deploying frontend nodegroup, label backend cluster so ingress controller pods run in backend nodes
// if (!enableFrontEndPool)){
//     backendLabels["frontend"] = "true";
// }

export const stackname = pulumi.getStack();

// PRIMARY NODE POOL VALUES
export const primary:NodePool = {
    initialNodeCount: primaryPool.getNumber("initialNodeCount") || 1,
    nodeCount: primaryPool.getNumber("nodeCount") || 0,
    cpuPlatform: primaryPool.get("cpuPlatform") || "Intel Skylake",
    nodeMachineType: primaryPool.get("nodeMachineType") || "n1-standard-2",
    diskSize: primaryPool.getNumber("diskSizeGb") || 80,
    diskType: primaryPool.get("diskType") || "pd-ssd",
    enableAutoScaling: primaryPool.requireBoolean("autoScaling"),
    minNodes: primaryPool.getNumber("minNodes") || 1,
    maxNodes: primaryPool.getNumber("maxNodes") || 4,
    preemptible: primaryPool.requireBoolean("preemptible"),
    nodePoolName: primaryPool.get("name") || "primary",
    labels: backendLabels,
};

// SECONDARY NODE POOL VALUES
export const secondary:NodePool = {
    initialNodeCount: secondaryPool.getNumber("initialNodeCount") || 1,
    nodeCount: secondaryPool.getNumber("nodeCount") || 0,
    cpuPlatform: secondaryPool.get("cpuPlatform") || "Intel Skylake",
    nodeMachineType: secondaryPool.get("nodeMachineType") || "n1-standard-2",
    diskSize: secondaryPool.getNumber("diskSizeGb") || 80,
    diskType: secondaryPool.get("diskType") || "pd-ssd",
    enableAutoScaling: secondaryPool.requireBoolean("autoScaling"),
    minNodes: secondaryPool.getNumber("minNodes") || 1,
    maxNodes: secondaryPool.getNumber("maxNodes") || 4,
    preemptible: secondaryPool.requireBoolean("preemptible"),
    nodePoolName: secondaryPool.get("name") || "secondary",
    labels: backendLabels,
};

// SECONDARY NODE POOL VALUES
export const ds:NodePool = {
    initialNodeCount: dsPool.getNumber("initialNodeCount") || 1,
    nodeCount: dsPool.getNumber("nodeCount") || 0,
    cpuPlatform: dsPool.get("cpuPlatform") || "Intel Skylake",
    nodeMachineType: dsPool.get("nodeMachineType") || "n1-standard-2",
    diskSize: dsPool.getNumber("diskSizeGb") || 80,
    diskType: dsPool.get("diskType") || "pd-ssd",
    enableAutoScaling: dsPool.getBoolean("enableAutoScaling") || true,
    minNodes: dsPool.getNumber("minNodes") || 1,
    maxNodes: dsPool.getNumber("maxNodes") || 4,
    preemptible: dsPool.getBoolean("preemptible") || false,
    nodePoolName: dsPool.get("name") || "secondary",
    labels: backendLabels,
    taints: {
        key: "WorkerDedicatedDS",
        value: "true",
        effect: "NO_SCHEDULE"
    },
};




