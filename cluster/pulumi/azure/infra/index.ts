import * as pulumi from "@pulumi/pulumi";
import * as azure from "@pulumi/azure";
import * as azuread from "@pulumi/azuread";

const stackConfig = new pulumi.Config();

// Initialize cluster configuration
export interface clusterConfiguration {
    location: string;
    clusterResourceGroupName: string;
    servicePrincipalId: string;
    servicePrincipalSecret: string;
}

// Initialize infra configuration
export interface infrastructureConfig {
    adAppId: pulumi.Output<string>;
    adSp: pulumi.Output<string>;
    adSpPassword: azuread.ServicePrincipalPassword;
    resourceGroupName: pulumi.Output<string>;
}

// Set values for cluster configuration
export const clusterConfig : clusterConfiguration =  {
    location: stackConfig.require("location"),
    clusterResourceGroupName: stackConfig.require("clusterResourceGroupName"),
    servicePrincipalId: stackConfig.get("servicePrincipalId") || "", 
    servicePrincipalSecret: stackConfig.require("servicePrincipalSecret")
}

// Function to create infrastructure
function createInfrastructure(): infrastructureConfig {

    // Create an Azure Resource Group
    const resourceGroup = new azure.core.ResourceGroup("resourceGroup", {
        location: clusterConfig.location,
        name: clusterConfig.clusterResourceGroupName,
        tags: {
            deploymentType: "cdm"
        }
    });

    // Create the AD service principal for the K8s cluster.
    let adApp = new azuread.Application("aks");
    let adSp = new azuread.ServicePrincipal("aksSp", { applicationId: adApp.applicationId });
    let adSpPassword = new azuread.ServicePrincipalPassword("aksSpPassword", {
        servicePrincipalId: adSp.id,
        value: clusterConfig.servicePrincipalSecret,
        endDate: "2099-01-01T00:00:00Z",
    }, {dependsOn: [adApp, adSp]});

    let val:infrastructureConfig = {
        adAppId: adApp.applicationId, 
        adSp: adSp.objectId,
        adSpPassword: adSpPassword, 
        resourceGroupName: resourceGroup.name
    }
    return val;
}
export const infra: infrastructureConfig = createInfrastructure();
export const adAppId = infra.adAppId
export const adSpId = infra.adSpPassword.id
export const adSpPassword = infra.adSpPassword.value
export const resourceGroupName = infra.resourceGroupName
export const location = clusterConfig.location

