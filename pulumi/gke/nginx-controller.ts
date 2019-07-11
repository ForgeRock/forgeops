import * as k8s from "@pulumi/kubernetes";
import { clusterProvider } from "./cluster";
import * as gcp from "@pulumi/gcp";
import { ip } from "./config";

// Create nginx namespace
const nsnginx = new k8s.core.v1.Namespace("nginx", { metadata: { name: "nginx" }}, { provider: clusterProvider });

// Adds namespace to correct Helm field
function addNamespace(o: any) {
    if (o !== undefined) {
        o.metadata.namespace = "nginx";
    }
}

// Check to see if static IP address has been provided. If not, create 1
function assignIp() {
    if (ip !== undefined) {
        return ip;
    } else {
        const staticIp = new gcp.compute.Address("cdm-ingress-ip", {
            addressType: "EXTERNAL",
        });
        return staticIp.address;
    }
}

export const lbIp = assignIp();

// Deploy nginx-controller Helm chart
export const nginx = new k8s.helm.v2.Chart("nginx-ingress", {
    repo: "stable",
    version: "0.24.1",
    chart: "nginx-ingress",
    transformations: [addNamespace],
    namespace: "nginx",
    values: {
        rbac: {create: true},
        controller: {
            publishService: {enabled: true},
            stats: {enabled: true},
            service: {
                type: "LoadBalancer",
                externalTrafficPolicy: "Local",
                loadBalancerIP: lbIp
            },
            image: {tag: "0.24.1"}
        }
    }
}, { dependsOn: [nsnginx], provider: clusterProvider });




