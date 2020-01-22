import * as pulumi from "@pulumi/pulumi";
import * as gke from "./cluster"
import * as config from "./config";
import { Config } from "@pulumi/pulumi";

// Reference configuration values
const stackConfig = new Config();

/************** INFRA IMPORTS **************/
const infraReference = new pulumi.StackReference(config.stackRef);
const infra = {
    vpcId: infraReference.getOutput("vpcId"),
    subnetId: infraReference.getOutput("subnetId"),
}

/******************* VPC *******************/
// Function to either grab VPC from gcp-infra project or copy VPC name from user
function assignVpc() {
    // Create new network if not provided
    if (infra.vpcId === undefined) {
        if (config.vpcName === undefined) { return stackConfig.require("vpcName") }
        else return config.vpcName;
    }
    else { return infra.vpcId;}
}

// Call above function
export const network: any = assignVpc();


/***************** GKE *****************/

// Create GKE cluster
const cluster = gke.createCluster(network, infra.subnetId);

// Expose kubeconfig
export const kubeconfig = gke.createKubeconfig(cluster);

// Create cluster provider
const clusterProvider = gke.createClusterProvider(kubeconfig);

// Add Node Pools
const nodes = gke.addNodePools(cluster.name)

// Create storage classes
gke.createStorageClasses(clusterProvider);

// Create namespaces
gke.createNamespaces(clusterProvider);

//gke.createNetworkLoadbalancer(network, ip, cluster.instanceGroupUrls);

/************ NGINX INGRESS CONTROLLER ************/

// Export the nginx ingress IP.
export const loadbalancerIp = gke.assignIp();

// Deploy nginx ingress controller if enable = true
if (config.enableNginxIngress) {
    gke.deployIngressController(loadbalancerIp, clusterProvider, cluster, nodes)
}

/************ CERTIFICATE MANAGER ************/

//Deploy cert-manager if enable = true
if (config.enableCertManager){
    gke.deployCertManager(clusterProvider, cluster, nodes);
}

// ********************** PROMETHEUS **************
if (config.enablePrometheus){
    gke.createPrometheus(cluster, clusterProvider, nodes);
}

// ********************** PROMETHEUS ************** 
if (config.enableLocalSsdProvisioner){
    gke.deployLocalSsdProvisioner(cluster, clusterProvider);
}

const cmConfig = new pulumi.Config("certmanager");
export const key = cmConfig.require("tls-key")
export const cert = cmConfig.require("tls-crt")