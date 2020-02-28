import * as pulumi from "@pulumi/pulumi";
import * as k8s from "@pulumi/kubernetes";
import * as azure from "@pulumi/azure";
import * as clusterLib from "./cluster";
import * as config from "./config";

const cluster = clusterLib.createCluster();
export const kubeconfig = pulumi.all([cluster.kubeConfigRaw, cluster.name]).apply(([kc, name]) => {
    return kc.split(": " + name).join(": aks"); //replace any randon aks*** name in the kubeconfig to just "aks" for easier integration
})


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


const ipGroup = clusterLib.createIpGroup(k8sProvider);
const staticIp = clusterLib.createStaticIp(k8sProvider, ipGroup);
export const ipResourceGroupName = ipGroup.name
export const staticIpAddress = staticIp.ipAddress


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



