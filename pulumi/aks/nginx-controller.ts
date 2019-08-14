import * as k8s from "@pulumi/kubernetes";
import * as cluster from "./cluster";
import * as pulumi from "@pulumi/pulumi";
import * as config from "./config";
import * as azure from "@pulumi/azure";
import * as ingressController from "../packages/nginx-ingress-controller";
export let statIp: any;
export let ipGroup: any;

// If IP address and IP resource group not provided, create new otherwise get details
if ( config.staticIpName !== undefined ) {
    // Get static IP from config.ts
    statIp = pulumi.output(azure.network.getPublicIP({
        name: config.staticIpName,
        resourceGroupName: config.ipResourceGroupName
    }));

    // Get IP resource group from config.ts
    ipGroup = pulumi.output(azure.core.getResourceGroup({
        name: config.ipResourceGroupName
    }))
} else {
    // Create an Azure Resource Group to hold static IP
    ipGroup = new azure.core.ResourceGroup("ipResourceGroup", {
        location: config.location,
        name: pulumi.getStack() + "-ip-resource-group",
        tags: {
            deploymentType: "cdm"
        }
    });

    // Create static IP
    statIp = new azure.network.PublicIp("static-ip", {
        allocationMethod: "Static",
        location: config.location,
        name: pulumi.getStack() + "-static-ip",
        resourceGroupName: ipGroup.name,
        tags: {
            deployment: pulumi.getStack(),
        },
    });
};

export const roleAssignment = new azure.role.Assignment("ip-role", {
    principalId: cluster.adSp.objectId,
    roleDefinitionName: "Network Contributor",
    scope: ipGroup.id
});

const azLbType = {"service\.beta\.kubernetes\.io/azure-load-balancer-resource-group": "aks-small-ip-resource-group"};

// Set values for nginx Helm chart
export const nginxValues: ingressController.ChartArgs = {
    ip: statIp.ipAddress,
    version: config.nginxVersion,
    clusterProvider: cluster.k8sProvider,
    dependencies: [statIp,cluster.k8sProvider],
    annotations: azLbType
};


// Deploy Nginx Ingress Controller Helm chart
export const nginxControllerChart = new ingressController.NginxIngressController( nginxValues );

