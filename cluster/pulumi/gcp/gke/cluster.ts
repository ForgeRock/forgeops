import * as pulumi from "@pulumi/pulumi";
import * as gcp from "@pulumi/gcp";
import * as k8s from "@pulumi/kubernetes";
import * as config from "./config";
import * as localSsd from "./local-ssd-provisioner";

let zones = new Array(config.numOfZones) //array of availabity zones

const engVersionProperties = {location: config.region, versionPrefix: config.k8sVersion};
const latestMasterVersion = gcp.container.getEngineVersions(engVersionProperties).then(v => v.latestMasterVersion);
const latestNodeVersion = gcp.container.getEngineVersions(engVersionProperties).then(v => v.latestNodeVersion);

// Function to return list of Availability Zones
async function getAZs(numZones: number) {
    //Retrieve number of zones provide in stack file
    const available = await gcp.compute.getZones({
        region: gcp.config.region
    });
    
    for (const range = {value: 0}; range.value < numZones; range.value++) {
        zones[range.value] = available.names[range.value]
    };

    return zones
}

// Create node pool configuration
function createNP(nodeConfig: any, clusterName: pulumi.Output<string>) {
    return new gcp.container.NodePool(nodeConfig.nodePoolName, {
        cluster: clusterName,
        initialNodeCount: nodeConfig.nodeCount ? undefined : nodeConfig.initialNodeCount,
        version: latestNodeVersion,
        location: gcp.config.region,
        name: nodeConfig.nodePoolName,
        nodeConfig: {
            machineType: nodeConfig.nodeMachineType,
            diskSizeGb: nodeConfig.diskSize,
            diskType: nodeConfig.diskType,
            oauthScopes: [
                "https://www.googleapis.com/auth/compute",
                "https://www.googleapis.com/auth/devstorage.read_only",
                "https://www.googleapis.com/auth/logging.write",
                "https://www.googleapis.com/auth/monitoring",
                "https://www.googleapis.com/auth/servicecontrol",
                "https://www.googleapis.com/auth/service.management.readonly",
                "https://www.googleapis.com/auth/trace.append",
                //"https://www.googleapis.com/auth/cloud-platform"
            ],
            imageType: "COS",
            labels: nodeConfig.labels,
            taints: nodeConfig.taints ? nodeConfig.taints : undefined,
            preemptible: nodeConfig.preemptible,
            localSsdCount: nodeConfig.localSsdCount
        },
        nodeCount: nodeConfig.enableAutoScaling ? undefined : nodeConfig.nodeCount,
        autoscaling: nodeConfig.enableAutoScaling ? {
            maxNodeCount: nodeConfig.maxNodes,
            minNodeCount: nodeConfig.minNodes
        } : undefined,
        management: {
            autoRepair: true
        }
    })
}

// Select node pools to be configured in GKE cluster.

export function addNodePools(clusterName: pulumi.Output<string>) {
    var pools = [  createNP(config.primary, clusterName) ]
    if (config.enableSecondaryPool ) {
        pools.push(createNP(config.secondary, clusterName))
    }
    if( config.enableDSPool) {
        pools.push(createNP(config.ds, clusterName))
    }
    if( config.enableFrontEndPool) {
        pools.push(createNP(config.frontend, clusterName))
    }
    return pools;
}

// Create a GKE cluster
export function createCluster(network: any, subnetwork: pulumi.Output<any>) {
    return new gcp.container.Cluster(config.clusterName, {
        name: config.clusterName,
        initialNodeCount: 1,
        location: gcp.config.region,
        nodeLocations: getAZs(config.numOfZones),
        network: network,
        subnetwork: subnetwork,
        minMasterVersion: latestMasterVersion,
        addonsConfig: {
            horizontalPodAutoscaling: {
                disabled: config.disableHPA,
            },
            istioConfig: {
                disabled: config.disableIstio,
                auth: "AUTH_MUTUAL_TLS",
            }
        },
        loggingService: "logging.googleapis.com/kubernetes",
        monitoringService: "monitoring.googleapis.com/kubernetes",
        removeDefaultNodePool: true,
        resourceLabels: {
            modifiedby: config.username,
            deployedby: "pulumi",
            stackname: pulumi.getStack()
        }
    });
}

// Create kube config
export function createKubeconfig(cluster: gcp.container.Cluster) {
    return pulumi.
    all([ cluster.name, cluster.endpoint, cluster.masterAuth ]).
    apply(([ name, endpoint, masterAuth ]) => {
        const context = `${gcp.config.project}_${zones[0]}_${name}`;
        return `apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: ${masterAuth.clusterCaCertificate}
    server: https://${endpoint}
  name: ${context}
contexts:
- context:
    cluster: ${context}
    user: ${context}
  name: ${context}
current-context: ${context}
kind: Config
preferences: {}
users:
- name: ${context}
  user:
    auth-provider:
      config:
        cmd-args: config config-helper --format=json
        cmd-path: gcloud
        expiry-key: '{.credential.token_expiry}'
        token-key: '{.credential.access_token}'
      name: gcp
`;
});
};

// Create a Kubernetes provider instance that uses our cluster from above.
export function createClusterProvider(k8sConfig: pulumi.Output<string>) {

    return new k8s.Provider("dev-cluster-provider", {
        kubeconfig: k8sConfig,
    });
}

/********** Create Storage Classes **********/
export function createStorageClasses(clusterProvider: k8s.Provider) {
    new k8s.storage.v1.StorageClass("sc-fast", {
        metadata: { name: 'fast' },
        provisioner: 'kubernetes.io/gce-pd',
        parameters: { type: 'pd-ssd' },
    }, { provider: clusterProvider } );

    new k8s.storage.v1.StorageClass("sc-local-storage", {
        metadata: { name: 'local-storage' },
        provisioner: 'kubernetes.io/no-provisioner',
        volumeBindingMode: 'WaitForFirstConsumer',
    }, { provider: clusterProvider } );
}

/********** Create Namespaces **********/
export function createNamespaces(clusterProvider: k8s.Provider) {
    config.namespaces.forEach(ns => {
        new k8s.core.v1.Namespace(ns, { metadata: { name: "prod" }}, { provider: clusterProvider });
    });
}

// Check to see if static IP address has been provided. If not, create 1
export function assignIp() {
    const staticIp = new gcp.compute.Address(config.clusterName + "-ip", {
        addressType: "EXTERNAL"
    });
    return staticIp.address;
}

/************ LOCAL SSD PROVISIONER ************/

export function deployLocalSsdProvisioner(cluster: gcp.container.Cluster, provider: k8s.Provider) {
    const provisionerArgs: localSsd.PkgArgs = {
        version: config.localSsdVersion,
        namespaceName: config.localSsdNamespace,
        provider: provider,
        cluster: cluster
    }
    return new localSsd.LocalSsdProvisioner(provisionerArgs)
}