import * as pulumi from "@pulumi/pulumi";
import * as gcp from "@pulumi/gcp";
import * as k8s from "@pulumi/kubernetes";
import * as config from "./config";
import * as ingress from "../../packages/nginx-ingress-controller/index-gke";
import { Provider } from "@pulumi/gcp";
import * as cm from "../../packages/cert-manager";
import * as prometheus from "../../packages/prometheus";
import * as localSsd from "../../packages/local-ssd-provisioner";

// To be finished...
// export function createNetworkLoadbalancer(vpc: gcp.compute.Network, ip: gcp.compute.Address, instanceGroups: pulumi.Output<string[]>){
//     // firewall
//     // health check
//     const defaultHttpHealthCheck = new gcp.compute.HttpHealthCheck("default", {
//         checkIntervalSec: 5,
//         requestPath: "/healthz",
//         timeoutSec: 1,
//         unhealthyThreshold: 3,
//         port: 30080
//     });

//     const targetBackend = new gcp.compute.BackendService("targetBackend", {
//         healthChecks: defaultHttpHealthCheck.selfLink,
//         backends: [{
//             group: instanceGroups[0],

//         }]

//     });

//     const defaultForwardingRule = new gcp.compute.ForwardingRule("default", {
//         ports: ["80","443"],
//         target: targetBackend.selfLink,
//         loadBalancingScheme: "external",
//         network: vpc.selfLink,
//         region: gcp.config.region,
//         ipAddress: ip.address
//     });
// }

/** Method to return list of k8s full versions */
function getK8sVersion() {
    return gcp.container.getEngineVersions({
        location: gcp.config.zone,
        versionPrefix: config.k8sVersion,
    });
}

// Create node pool configuration
function createNP(nodeConfig: any): object {
    return {
        initialNodeCount: nodeConfig.nodeCount ? undefined : nodeConfig.initialNodeCount,
        version: getK8sVersion().latestNodeVersion,
        name: nodeConfig.nodePoolName,
        nodeConfig: {
            machineType: nodeConfig.nodeMachineType,
            diskSizeGb: nodeConfig.diskSize,
            diskType: nodeConfig.diskType,
            minCpuPlatform: nodeConfig.cpuPlatform,
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
            taints: nodeConfig.taints ? [nodeConfig.taints] : undefined,
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
    };
}

// Select node pools to be configured in GKE cluster.
function addNodePools() {
    if (config.enableSecondaryPool && config.enableDSPool) {
        return [
            createNP(config.primary),
            createNP(config.secondary),
            createNP(config.ds)
        ]
    } else if (config.enableSecondaryPool && !config.enableDSPool) {
        return [
            createNP(config.primary),
            createNP(config.secondary)
        ]
    } else {
        return [
            createNP(config.primary)
        ]
    };
}

// Create a GKE cluster
export function createCluster(network: any, subnetwork: pulumi.Output<any>) {
    return new gcp.container.Cluster(config.clusterName, {
        name: config.clusterName,
        nodeLocations: config.nodeZones,
        network: network,
        subnetwork: subnetwork,
        minMasterVersion: getK8sVersion().latestMasterVersion,
        addonsConfig: {
            horizontalPodAutoscaling: {
                disabled: config.disableHPA,
            },
            istioConfig: {
                disabled: config.disableIstio,
                auth: "AUTH_MUTUAL_TLS",
            }
        },
        nodePools: addNodePools(),
        loggingService: "logging.googleapis.com/kubernetes",
        monitoringService: "monitoring.googleapis.com/kubernetes",
        ipAllocationPolicy: {
            useIpAliases: true,
        },
        removeDefaultNodePool: false,
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
    if (config.ip !== undefined) {
        let a: pulumi.Output<string> = pulumi.concat(config.ip);
        return (a);
    } else {
        const staticIp = new gcp.compute.Address("ingress-ip", {
            addressType: "EXTERNAL",
        });
        return staticIp.address;
    }
}

/************ NGINX INGRESS CONTROLLER ************/

// Call ngin-ingress-controller package to deploy Nginx Ingress Controller
export function deployIngressController(ip: pulumi.Output<string>, clusterProvider: Provider, cluster: gcp.container.Cluster) {
    const nginxConfig = new pulumi.Config("nginx");

    // Set values for nginx Helm chart
    const nginxValues: ingress.ChartArgs = {
        ip: ip,
        version: config.nginxVersion,
        clusterProvider: clusterProvider,
        dependencies: [cluster]
    }

    // Deploy Nginx Ingress Controller Helm chart
    new ingress.NginxIngressController( nginxValues );
}

/************ CERTIFICATE MANAGER ************/

// Call cert-manager package to deploy cert-manager
export function deployCertManager(clusterProvider: Provider, cluster: gcp.container.Cluster) {
    const cmConfig = new pulumi.Config("certmanager");

    const cmArgs: cm.PkgArgs = {
        tlsKey: cmConfig.require("tls-key"),
        tlsCrt: cmConfig.require("tls-crt"),
        clusterProvider: clusterProvider,
        cloudDnsSa: cmConfig.get("clouddns") || "",
        dependsOn: [cluster],
        version: cmConfig.require("version"),
        useSelfSignedCert: cmConfig.requireBoolean("useselfsignedcert"),
    };

    // Deploy Cert Manager
    new cm.CertManager(cmArgs);
}

/************ PROMETHEUS OPERATOR ************/

export function createPrometheus(cluster: gcp.container.Cluster, provider: k8s.Provider){
    const prometheusArgs: prometheus.PkgArgs = {
        version: config.prometheusConfig.version,
        namespaceName: config.prometheusConfig.k8sNamespace,
        k8sVersion: config.k8sVersion,
        provider: provider,
        dependsOn: [cluster],
    }
    return new prometheus.Prometheus(prometheusArgs)
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