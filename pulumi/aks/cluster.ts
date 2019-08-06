import * as azure from "@pulumi/azure";
import * as azuread from "@pulumi/azuread";
import * as pulumi from "@pulumi/pulumi";
import * as k8s from "@pulumi/kubernetes";
import * as config from "./config";

// Create an Azure Resource Group
const resourceGroup = new azure.core.ResourceGroup("resourceGroup", {
    location: config.location,
    name: config.clusterResourceGroupName,
    tags: {
        deploymentType: "cdm"
    }
});

// Create the AD service principal for the K8s cluster.
export let adApp = new azuread.Application("aks");
export let adSp = new azuread.ServicePrincipal("aksSp", { applicationId: adApp.applicationId });
let adSpPassword = new azuread.ServicePrincipalPassword("aksSpPassword", {
    servicePrincipalId: adSp.id,
    value: config.servicePrincipalSecret,
    endDate: "2099-01-01T00:00:00Z",
});

// Now allocate an AKS cluster.
export const k8sCluster = new azure.containerservice.KubernetesCluster("aksCluster", {
    resourceGroupName: resourceGroup.name,
    location: config.location,
    agentPoolProfiles: [{
        name: "aksagentpool",
        count: config.nodeCount,
        vmSize: config.nodeSize,
    }],
    dnsPrefix: `${pulumi.getStack()}-kube`,
    linuxProfile: {
        adminUsername: "aksuser",
        sshKey: {
            keyData: config.sshPublicKey,
        },
    },
    servicePrincipal: {
        clientId: adApp.applicationId,
        clientSecret: adSpPassword.value,
    },
});

// export const loganalytics = new azure.operationalinsights.AnalyticsWorkspace("aksloganalytics", {
//     resourceGroupName: resourceGroup.name,
//     location: resourceGroup.location,
//     sku: "PerGB2018",
//     retentionInDays: 30,
// })

// // Enable the Monitoring Diagonostic control plane component logs and AllMetrics   
// export const azMonitoringDiagnostic = new azure.monitoring.DiagnosticSetting("aks", {
//     logAnalyticsWorkspaceId: loganalytics.id,
//     targetResourceId: k8sCluster.id,
//     logs:  [{
//         category: "kube-apiserver",
//         enabled : true,
    
//         retentionPolicy: {
//         enabled: true,
//         }
//     },
//     ],
//     metrics: [{
//         category: "AllMetrics",
    
//         retentionPolicy: {
//         enabled: true,
//         }
//     }],
// })

// Expose a K8s provider instance using our custom cluster instance.
export const k8sProvider = new k8s.Provider("aksK8s", {
    kubeconfig: k8sCluster.kubeConfigRaw,
});