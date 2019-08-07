import * as pulumi from "@pulumi/pulumi";
import * as azure from "@pulumi/azure";
import * as cluster from "./cluster";
import * as config from "./config";
import "./nginx-controller";

export let statIp: pulumi.Output<string>;
export let ipGroup: any;

if ( config.staticIp !== undefined ) {
    statIp = pulumi.output(config.staticIp).apply(i => i);
    ipGroup = config.ipResourceGroupName;
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
    statIp = (new azure.network.PublicIp("static-ip", {
        allocationMethod: "Static",
        location: config.location,
        name: pulumi.getStack() + "-static-ip",
        resourceGroupName: ipGroup.name,
        tags: {
            deployment: pulumi.getStack(),
        },
    })).ipAddress;
};

export const roleAssignment = new azure.role.Assignment("ip-role", {
    principalId: cluster.adSp.objectId,
    roleDefinitionName: "Network Contributor",
    scope: ipGroup.id
});

export const ip = statIp;

// Expose a K8s provider instance using our custom cluster instance.
export const kubeconfig = cluster.k8sCluster.kubeConfigRaw;
