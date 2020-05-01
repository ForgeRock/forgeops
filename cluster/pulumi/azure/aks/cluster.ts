import * as azure from "@pulumi/azure";
import * as pulumi from "@pulumi/pulumi";
import * as k8s from "@pulumi/kubernetes";
import * as config from "./config";

export function createResourceGroup(location: pulumi.Output<any>, groupName: string) {
    // Create an Azure Resource Group
    return new azure.core.ResourceGroup("resourceGroup", {
        location: location,
        name: groupName,
        tags: {
            deploymentType: "cdm"
        }
    });
}

export function createCluster(infra: any, resourceGroup: azure.core.ResourceGroup): azure.containerservice.KubernetesCluster {

    return new azure.containerservice.KubernetesCluster("aksCluster", {
        //name: config.clusterConfig.clusterName,
        resourceGroupName: resourceGroup.name,
        location: infra.location,
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
            clientId: infra.adAppId,
            clientSecret: infra.adSpPassword,
        },
        networkProfile: {
            networkPlugin: "azure",
            loadBalancerSku: "standard"
        }
    }, {dependsOn: resourceGroup});
}

export function createNodeGroup(nodeGroupConfig: config.nodeGroupConfiguration,
                                cluster: azure.containerservice.KubernetesCluster,
                                taints?: string[] | undefined) {

        new azure.containerservice.KubernetesClusterNodePool(`${nodeGroupConfig.namespace}Worker`, {
            name: `${nodeGroupConfig.namespace}`.toLowerCase(),
            kubernetesClusterId: cluster.id,
            enableNodePublicIp: false,
            availabilityZones: Array.from(Array(config.clusterConfig.numOfAzs).keys()).map(a=>String(a+1)), //converts "3" to ["1","2","3"]
            nodeTaints: taints,
            vmSize: nodeGroupConfig.instanceType,
            osDiskSizeGb: nodeGroupConfig.diskSizeGb,
            nodeLabels: nodeGroupConfig.nodeLabels,
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

export function createStaticIp(ipResGroup: pulumi.Output<any>, loc: pulumi.Output<any>): azure.network.PublicIp{

    // Create static IP
    return new azure.network.PublicIp("static-ip", {
        allocationMethod: "Static",
        location: loc,
        name: pulumi.getStack() + "-static-ip",
        resourceGroupName: ipResGroup,
        sku: "Standard",
        tags: {
            deployment: pulumi.getStack(),
        },
    });
}

