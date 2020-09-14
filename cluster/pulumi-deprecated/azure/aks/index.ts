import * as pulumi from "@pulumi/pulumi";
import * as k8s from "@pulumi/kubernetes";
import * as clusterLib from "./cluster";
import * as config from "./config";

const infraReference = new pulumi.StackReference("azure-infra");

const infra = {
    adAppId: infraReference.getOutput("adAppId"),
    adSpObjectId: infraReference.requireOutput("adSpObjectId"),
    adSpPassword: infraReference.requireOutput("adSpPassword"),
    location: infraReference.requireOutput("location"),
    ipResourceGroupName: infraReference.requireOutput("ipResourceGroupName")
}

// ********************** RESOURCE GROUP *******************
const resourceGroup = clusterLib.createResourceGroup(infra.location, config.clusterConfig.clusterResourceGroupName);

// ********************** AKS CLUSTER *******************
const cluster = clusterLib.createCluster(infra, resourceGroup);
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

// ********************** STATIC IP **************
const staticIp = clusterLib.createStaticIp(infra.ipResourceGroupName, infra.location);

export const staticIpAddress = staticIp.ipAddress
export const staticIpResourceGroup = infra.ipResourceGroupName




