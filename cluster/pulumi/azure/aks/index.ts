import * as pulumi from "@pulumi/pulumi";
import * as k8s from "@pulumi/kubernetes";
import * as azure from "@pulumi/azure";
import * as clusterLib from "./cluster";
import * as config from "./config";

const cluster = clusterLib.createCluster();
export const kubeconfig = cluster.kubeConfigRaw;

const k8sProvider = new k8s.Provider("aksK8s", {
    kubeconfig: cluster.kubeConfigRaw,
});

if (config.dsNodeGroupConfig.enable){
    let taints = ["WorkerDedicatedDS=true:NoSchedule"];
    clusterLib.createNodeGroup(config.dsNodeGroupConfig, cluster, taints);
}

if (config.frontendNodeGroupConfig.enable){
    let taints =  ["WorkerAttachedToExtLoadBalancer=true:NoSchedule"];
    clusterLib.createNodeGroup(config.frontendNodeGroupConfig, cluster, taints);
}

// ********************** NAMESPACE *******************
new k8s.core.v1.Namespace("prod", { metadata: { name: "prod" }}, { provider: k8sProvider });

// ********************** STORAGE CLASSES **************
clusterLib.createStorageClasses(k8sProvider)


export const ipGroup = clusterLib.createIpGroup(k8sProvider);
export const staticIp = clusterLib.createStaticIp(k8sProvider, ipGroup);

// Assign permission to cluster SP to access IP resource group
const roleAssignment = new azure.role.Assignment("ip-role", {
    principalId: config.infra.adSp.objectId,
    roleDefinitionName: "Network Contributor",
    scope: ipGroup.id
});

if (config.clusterConfig.acrResourceGroupName) {
    // Assign permission to cluster SP to pull images from ACR
    new azure.role.Assignment("acr-role", {
        principalId: config.infra.adSp.objectId,
        roleDefinitionName: "AcrPull",
        scope: pulumi.output(azure.core.getResourceGroup({name: config.clusterConfig.acrResourceGroupName})).id,
    });
}

// ********************** INGRESS CONTROLLER **************
if (config.ingressConfig.enable) {
    clusterLib.createNginxIngress(k8sProvider, ipGroup, staticIp)
}

// ********************** CERTIFICATE MANAGER **************
if (config.cmConfig.enable){
    clusterLib.createCertManager(k8sProvider)
}

// ********************** PROMETHEUS **************
if (config.prometheusConfig.enable){
    clusterLib.createPrometheus(k8sProvider);
}



