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
gke.addNodePools(cluster.name)

// Create storage classes
gke.createStorageClasses(clusterProvider);

// Create namespaces
gke.createNamespaces(clusterProvider);

let loadbalancerIp

// Create Static IP or Export the static ingress IP.
if (config.ip){
    loadbalancerIp = gke.assignIp();
}

export const ip = loadbalancerIp

// Deploy local ssd provisioner
if (config.enableLocalSsdProvisioner){
    gke.deployLocalSsdProvisioner(cluster, clusterProvider);
}
