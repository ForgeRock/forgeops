import * as gcp from "@pulumi/gcp";
import { BackendService } from "@pulumi/gcp/compute";

/************* VPC CONFIGURATION *************/

// Function to create a new VPC
export function createVpc() {
    // Create new network if not provided
    return new gcp.compute.Network("vpc", {
        //ipv4Range: "192.168.0.0/16",
        autoCreateSubnetworks: false
    });
}

/******************* SUBNETS *******************/

export function createSubnetworks(vpc: gcp.compute.Network){
    return new gcp.compute.Subnetwork("public-subnet", {
        ipCidrRange: "192.168.16.0/20",
        network: vpc.selfLink,
        region: gcp.config.region,
    });
    // new gcp.compute.Subnetwork("private-subnet", {
    //     ipCidrRange: "192.168.32.0/20",
    //     network: vpc.selfLink,
    //     region: gcp.config.region,
    // });
}


 