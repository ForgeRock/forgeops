import * as pulumi from "@pulumi/pulumi";

const stackConfig = new pulumi.Config();

// **************** LABELS ****************
type nodeLabel = {[key: string]: string};
let backendLabels: nodeLabel = {
    "deployedby": "Pulumi",
    "backend": "true",
    "forgerock.io/role": "backend"
};

let frontendLabels: nodeLabel  = {
    "frontend": "true",
    "forgerock.io/role": "frontend"
};
let dsLabels: nodeLabel = {
    "ds": "true",
    "forgerock.io/role": "ds"
};

export interface clusterConfiguration {
    clusterResourceGroupName: string;
    sshPublicKey: string;
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
    nodeLabels: nodeLabel; 
    config: pulumi.Config;
}

function getNodeGroupConfig(namespace : string): nodeGroupConfiguration{
    let nodeGroupLabel: nodeLabel;
    if (namespace == "primarynodes") {
        nodeGroupLabel = backendLabels;
    }
    else if (namespace == "frontendnodes") {
        nodeGroupLabel = frontendLabels;
    }
    else if (namespace == "dsnodes") {
        nodeGroupLabel = dsLabels;
    }
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
       nodeLabels: nodeGroupLabel,
        config: tempconfig,
    };
    return val;
};
export const primaryNodeGroupConfig = getNodeGroupConfig("primarynodes");
export const frontendNodeGroupConfig = getNodeGroupConfig("frontendnodes");
export const dsNodeGroupConfig = getNodeGroupConfig("dsnodes");


export const clusterConfig : clusterConfiguration =  {
    clusterResourceGroupName: stackConfig.require("clusterResourceGroupName"),
    sshPublicKey: stackConfig.require("sshPublicKey"),
    k8sVersion: stackConfig.require("k8sVersion"),
    clusterName: pulumi.getStack(),
    numOfAzs: stackConfig.getNumber("numOfAzs"),
}
