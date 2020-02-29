import * as pulumi from "@pulumi/pulumi";
import * as azure from "@pulumi/azure";
import * as azuread from "@pulumi/azuread";

const stackConfig = new pulumi.Config();

// Initialize cluster configuration
interface clusterConfiguration {
    location: string;
    servicePrincipalId: string;
    servicePrincipalSecret: string;
    acrResourceGroupName: string | undefined;
}

// Initialize infra configuration
interface infrastructureConfig {
    adAppId: pulumi.Output<string>;
    adSpObjectId: pulumi.Output<string>;
    adSpPassword: azuread.ServicePrincipalPassword;
}

// Set values for cluster configuration
const clusterConfig : clusterConfiguration =  {
    location: stackConfig.require("location"), 
    servicePrincipalId: stackConfig.get("servicePrincipalId") || "", 
    servicePrincipalSecret: stackConfig.require("servicePrincipalSecret"),
    acrResourceGroupName: stackConfig.get("acrResourceGroupName") || undefined
}

// Function to create infrastructure
function createInfrastructure(): infrastructureConfig {

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
        adSpObjectId: adSp.objectId,
        adSpPassword: adSpPassword, 
    }
    return val;
}

const infra: infrastructureConfig = createInfrastructure();

function createIpGroup(): azure.core.ResourceGroup{
    // Create an Azure Resource Group to hold static IP
    return new azure.core.ResourceGroup("ipResourceGroup", {
        location: clusterConfig.location,
        name: pulumi.getStack() + "-ip-resource-group",
        tags: {
            deploymentType: "cdm"
        }
    });
}

// Assign permission to cluster SP to access IP resource group
function createRoleAssignment(ipGroupId: pulumi.Output<string>) {
    return new azure.role.Assignment("ip-role", {
        principalId: infra.adSpObjectId,
        roleDefinitionName: "Network Contributor",
        scope: ipGroupId
    });
}

if (clusterConfig.acrResourceGroupName) {
    // Assign permission to cluster SP to pull images from ACR
    new azure.role.Assignment("acr-role", {
        principalId: infra.adSpObjectId,
        roleDefinitionName: "AcrPull",
        scope: pulumi.output(azure.core.getResourceGroup({name: clusterConfig.acrResourceGroupName})).id,
    });
}

const ipGroup = createIpGroup()
createRoleAssignment(ipGroup.id)

//export const 
export const adSpObjectId = infra.adSpObjectId
export const adAppId = infra.adAppId
export const adSpId = infra.adSpPassword.id
export const adSpPassword = infra.adSpPassword.value
export const ipResourceGroupName = ipGroup.name
export const location = clusterConfig.location

