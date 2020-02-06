import * as azure from "@pulumi/azure";
import * as pulumi from "@pulumi/pulumi";
import * as k8s from "@pulumi/kubernetes";
import * as config from "./config";

export function createCluster(): azure.containerservice.KubernetesCluster {

    return new azure.containerservice.KubernetesCluster("aksCluster", {
        resourceGroupName: config.infra.resourceGroup.name,
        location: config.clusterConfig.location,
        kubernetesVersion: config.clusterConfig.k8sVersion,
        defaultNodePool: {
            name: "workernodes",
            type: "VirtualMachineScaleSets",
            availabilityZones: Array.from(Array(config.clusterConfig.numOfAzs).keys()).map(a=>String(a+1)), //converts "3" to ["1","2","3"]
            vmSize: config.primaryNodeGroupConfig.instanceType,
            osDiskSizeGb: config.primaryNodeGroupConfig.diskSizeGb,
            nodeCount: config.primaryNodeGroupConfig.nodeCount,
            minCount: config.primaryNodeGroupConfig.enableAutoScaling ? config.primaryNodeGroupConfig.minNodes : undefined,
            maxCount: config.primaryNodeGroupConfig.enableAutoScaling ? config.primaryNodeGroupConfig.maxNodes : undefined,
            enableAutoScaling: config.primaryNodeGroupConfig.enableAutoScaling
        },
        dnsPrefix: `${pulumi.getStack()}-kube`,
        linuxProfile: {
            adminUsername: "aksuser",
            sshKey: {
                keyData: config.clusterConfig.sshPublicKey,
            },
        },
        servicePrincipal: {
            clientId: config.infra.adApp.applicationId,
            clientSecret: config.infra.adSpPassword.value,
        },
        networkProfile: {
            networkPlugin: "azure",
            loadBalancerSku: "standard"
        }
    }, {dependsOn: [config.infra.adApp, config.infra.adSp, config.infra.adSpPassword, config.infra.resourceGroup]});
}

export function createNodeGroup(nodeGroupConfig: config.nodeGroupConfiguration, 
    cluster: azure.containerservice.KubernetesCluster, taints?: string[] | undefined) {
        
        new azure.containerservice.KubernetesClusterNodePool(`${nodeGroupConfig.namespace}Worker`, {
            name: `${nodeGroupConfig.namespace}`.toLowerCase(),
            kubernetesClusterId: cluster.id,
            enableNodePublicIp: false,
            availabilityZones: Array.from(Array(config.clusterConfig.numOfAzs).keys()).map(a=>String(a+1)), //converts "3" to ["1","2","3"]
            nodeTaints: taints,
            vmSize: nodeGroupConfig.instanceType,
            osDiskSizeGb: nodeGroupConfig.diskSizeGb,
            nodeCount: nodeGroupConfig.nodeCount,
            minCount: nodeGroupConfig.enableAutoScaling ? nodeGroupConfig.minNodes : undefined,
            maxCount: nodeGroupConfig.enableAutoScaling ? nodeGroupConfig.maxNodes : undefined,
            enableAutoScaling: nodeGroupConfig.enableAutoScaling

    });
}

export function createStorageClasses(provider: k8s.Provider){
    // Create Storage Classes
    new k8s.storage.v1.StorageClass("sc-standard", {
        metadata: { name: 'standard' },
        provisioner: 'kubernetes.io/azure-disk',
        parameters: {
            storageaccounttype: 'Standard_LRS',
            kind: 'Managed'
        }
    }, { provider: provider } );

    new k8s.storage.v1.StorageClass("sc-premium", {
        metadata: { name: 'fast' },
        provisioner: 'kubernetes.io/azure-disk',
        parameters: {
            storageaccounttype: 'Premium_LRS',
            kind: 'Managed'
        }
    }, { provider: provider } );
}

export function createIpGroup(provider: k8s.Provider): azure.core.ResourceGroup{
    let ipGroup : any
    if ( config.clusterConfig.staticIpName !== undefined ) {
        ipGroup = pulumi.output(azure.core.getResourceGroup({
            name: config.clusterConfig.ipResourceGroupName
        }))
    }
    else {
        // Create an Azure Resource Group to hold static IP
        ipGroup = new azure.core.ResourceGroup("ipResourceGroup", {
            location: config.clusterConfig.location,
            name: pulumi.getStack() + "-ip-resource-group",
            tags: {
                deploymentType: "cdm"
            }
        });
    }
    return ipGroup;
}

export function createStaticIp(provider: k8s.Provider, ipGroup: azure.core.ResourceGroup): azure.network.PublicIp{
    let staticIp : any
    if ( config.clusterConfig.staticIpName !== undefined ) {
        // Get static IP from config.ts
        staticIp = pulumi.output(azure.network.getPublicIP({
            name: config.clusterConfig.staticIpName,
            resourceGroupName: config.clusterConfig.ipResourceGroupName,
        }));
    }
    else {
        // Create static IP
        staticIp = new azure.network.PublicIp("static-ip", {
            allocationMethod: "Static",
            location: config.clusterConfig.location,
            name: pulumi.getStack() + "-static-ip",
            resourceGroupName: ipGroup.name,
            sku: "Standard",
            tags: {
                deployment: pulumi.getStack(),
            },
        });
    }
    return staticIp;
}