import * as azure from "@pulumi/azure";
import * as pulumi from "@pulumi/pulumi";

const config = new pulumi.Config();

// ** GENERAL CONFIG **
export const location = config.get("location") || azure.Locations.EastUS;
export const clusterResourceGroupName = config.get("clusterResourceGroupName") || "aks-cluster";
// If you have a static IP you want to provide, please also provide the resource group name that contains the IP.
export const staticIp = config.get("staticIp");
export let ipResourceGroupName: any;
if ( staticIp !== undefined ) {
    ipResourceGroupName = config.require("ipResourceGroupName");
}

// ** AZURE AD CONFIG **
export const servicePrincipalId = config.get("servicePrincipalId")
export const servicePrincipalSecret = config.require("servicePrincipalSecret")

// ** CLUSTER CONFIG **
export const nodeCount = config.getNumber("nodeCount") || 2;
export const nodeSize = config.get("nodeSize") || "Standard_DS2_v2";
export const clusterName = config.require("clusterName");
export const sshPublicKey = config.require("sshPublicKey");
export const nginxVersion = config.get("nginxVersion") || "0.25.0";