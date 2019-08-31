import * as pulumi from "@pulumi/pulumi";
import * as gcp from "@pulumi/gcp";
import * as k8s from "@pulumi/kubernetes";
import { 
    nodeCount, 
    nodeMachineType, 
    clusterName, 
    enablePreemptible, 
    k8sVersion,
    nodeZones,
    network, 
    cpuPlatform, 
    diskSize,
    diskType,
    minNodes,
    maxNodes
} from "./config";

function assignVpc() {
    // Create new network if not provided
    if (network !== undefined) {
        const vpcNetwork = network;
        return vpcNetwork;
    } else {
        const vpcNetwork = new gcp.compute.Network("cdm-network", {});
        return vpcNetwork.name;
    }
}

export const vpc = assignVpc()

// Create a GKE cluster
const cluster = new gcp.container.Cluster("cdm-cluster", {
    name: clusterName,
    initialNodeCount: 1,
    //location: zone,
    nodeLocations: nodeZones,
    network: vpc,
    subnetwork: vpc,
    minMasterVersion: k8sVersion,
    addonsConfig: {
        horizontalPodAutoscaling: {
            disabled: false,
        },
        istioConfig: {
            disabled: true,
            auth: "AUTH_MUTUAL_TLS",
        }
    },
    loggingService: "logging.googleapis.com/kubernetes",
    monitoringService: "monitoring.googleapis.com/kubernetes",
    ipAllocationPolicy: {
        useIpAliases: true,
    },
    removeDefaultNodePool: true
});

//Setup NodePools
export const primaryPool = new gcp.container.NodePool("primary", {
    cluster: cluster.name,
    initialNodeCount: nodeCount,
    //location: zone,
    nodeConfig: {
        machineType: nodeMachineType,
        diskSizeGb: diskSize,
        diskType: diskType, 
        minCpuPlatform: cpuPlatform,
        oauthScopes: [
            "https://www.googleapis.com/auth/compute",
            "https://www.googleapis.com/auth/devstorage.read_only",
            "https://www.googleapis.com/auth/logging.write",
            "https://www.googleapis.com/auth/monitoring",
            //"https://www.googleapis.com/auth/cloud-platform"
        ],
        imageType: "COS",
        labels: {
            deployedby: "Pulumi"
        },
        preemptible: enablePreemptible
    },
    autoscaling: {
        maxNodeCount: maxNodes,
        minNodeCount: minNodes
    },
    management: {
        autoRepair: true
    }
});

// Export the Cluster name
//export const clusterName = cluster.name;

export const k8sConfig = pulumi.
    all([ cluster.name, cluster.endpoint, cluster.masterAuth ]).
    apply(([ name, endpoint, masterAuth ]) => {
        const context = `${gcp.config.project}_${gcp.config.zone}_${name}`;
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

// Create a Kubernetes provider instance that uses our cluster from above.
export let clusterProvider = new k8s.Provider("cdm-cluster-provider", {
    kubeconfig: k8sConfig,
});