import * as pulumi from "@pulumi/pulumi";
import * as azure from "@pulumi/azure";
import * as azuread from "@pulumi/azuread";

const stackConfig = new pulumi.Config();
// const infraReference = new pulumi.StackReference("aws-infra"); 

export interface ingressConfiguration {
    enable: boolean;
    k8sNamespace: string;
    version: string;
}

export interface certManagerConfiguration{

    enable: boolean;
    useSelfSignedCert: boolean;
    tlsCrt?: string;
    tlsKey?: string;
    cloudDnsSa: string;
    version: string;
}

export interface prometheusConfiguration {
    enable: boolean;
    k8sNamespace: string;
    version: string;
}

export interface clusterConfiguration {
    location: string;
    clusterResourceGroupName: string;
    servicePrincipalId: string;
    servicePrincipalSecret: string;
    sshPublicKey: string;
    staticIpName: string | undefined;
    ipResourceGroupName: string | undefined;
    acrResourceGroupName: string | undefined;
    k8sVersion: string;
    clusterName: string;
    numOfAzs: number;
}

export interface nodeGroupConfiguration {
    enable: boolean;
    enableAutoScaling: boolean;
    namespace: string;
    diskSizeGb: number;
    instanceType: string;
    maxNodes: number;
    minNodes: number;
    nodeCount: number;
    config: pulumi.Config;
}

export interface infrastructureConfig {
    adApp: azuread.Application;
    adSp: azuread.ServicePrincipal;
    adSpPassword: azuread.ServicePrincipalPassword;
    resourceGroup: azure.core.ResourceGroup;
}

function getIngressConfig(namespace : string): ingressConfiguration {
    let ingressConfig = new pulumi.Config(namespace);
    let val: ingressConfiguration = {
            enable: ingressConfig.requireBoolean("enable"),
            version: ingressConfig.require("version"),
            k8sNamespace: ingressConfig.require("k8sNamespace"),
    };
    return val;
}
export const ingressConfig = getIngressConfig("nginxingress");


function getCertManagerConfig(namespace : string): certManagerConfiguration{
    let cmConfig = new pulumi.Config(namespace);
    let val: certManagerConfiguration = {
        enable: cmConfig.requireBoolean("enable"),
        useSelfSignedCert: cmConfig.requireBoolean("useselfsignedcert"),
        version: cmConfig.require("version"),
        tlsKey: cmConfig.get("tls-key") || "",
        tlsCrt: cmConfig.get("tls-crt") || "",
        cloudDnsSa: cmConfig.get("clouddns") || "",
    }
    return val;
}
export const cmConfig = getCertManagerConfig("certmanager");

function getPrometheusConfig(namespace: string): prometheusConfiguration {
    let promconfig = new pulumi.Config(namespace);
    let val: prometheusConfiguration = {
        enable: promconfig.requireBoolean("enable"),
        version: promconfig.require("version"),
        k8sNamespace: promconfig.require("k8sNamespace")
    } 
    return val;
}
export const prometheusConfig = getPrometheusConfig("prometheus");

function getNodeGroupConfig(namespace : string): nodeGroupConfiguration{
    let tempconfig = new pulumi.Config(namespace);
    let val: nodeGroupConfiguration = {
        enable: tempconfig.getBoolean("enable") == undefined ? true : tempconfig.requireBoolean("enable"),
        enableAutoScaling: tempconfig.getBoolean("enableAutoScaling") == undefined ? false : tempconfig.requireBoolean("enableAutoScaling"),
        namespace: namespace.substring(0,12), //azure only support the names with 12chars
        diskSizeGb: tempconfig.requireNumber("diskSizeGb"),
        instanceType: tempconfig.require("instanceType"),
        maxNodes: tempconfig.requireNumber("maxNodes"),
        minNodes: tempconfig.requireNumber("minNodes"),
        nodeCount: tempconfig.requireNumber("nodeCount"),
        config: tempconfig,
    };
    return val;
};
export const primaryNodeGroupConfig = getNodeGroupConfig("primarynodes");
export const frontendNodeGroupConfig = getNodeGroupConfig("frontendnodes");
export const dsNodeGroupConfig = getNodeGroupConfig("dsnodes");


export const clusterConfig : clusterConfiguration =  {
    location: stackConfig.require("location"),
    clusterResourceGroupName: stackConfig.require("clusterResourceGroupName"),
    servicePrincipalId: stackConfig.get("servicePrincipalId") || "", 
    servicePrincipalSecret: stackConfig.require("servicePrincipalSecret"),
    sshPublicKey: stackConfig.require("sshPublicKey"),
    staticIpName: stackConfig.get("staticIpName") || undefined,
    ipResourceGroupName: stackConfig.get("staticIpName") == undefined ? undefined : stackConfig.require("ipResourceGroupName"),
    acrResourceGroupName: stackConfig.get("acrResourceGroupName") || undefined,
    k8sVersion: stackConfig.require("k8sVersion"),
    clusterName: pulumi.getStack(),
    numOfAzs: stackConfig.getNumber("numOfAzs"),
}

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
        adApp: adApp, 
        adSp: adSp,
        adSpPassword: adSpPassword, 
        resourceGroup: resourceGroup
    }
    return val;
}
export const infra: infrastructureConfig = createInfrastructure();