import * as gcp from "@pulumi/gcp";
import * as pulumi from "@pulumi/pulumi";
import * as config from "./config";
import * as cluster from "./cluster";
import * as ingress from "../packages/nginx-ingress-controller";

// Check to see if static IP address has been provided. If not, create 1
function assignIp() {
    if (config.ip !== undefined) {
        let a: pulumi.Output<string> = pulumi.concat(config.ip);
        return (a);
    } else {
        const staticIp = new gcp.compute.Address("cdm-ingress-ip", {
            addressType: "EXTERNAL",
        });
        return staticIp.address;
    }
}

export let lbIp:pulumi.Output<string>;
export let nginx:ingress.NginxIngressController;


if( config.enableNginxIngress ) {
    lbIp = assignIp();
    //
    // Set values for nginx Helm chart
    const nginxValues: ingress.ChartArgs = {
        ip: lbIp,
        version: config.nginxVersion,
        clusterProvider: cluster.clusterProvider,
        dependencies: [cluster.primaryPool]
    }

    // Deploy Nginx Ingress Controller Helm chart
    nginx = new ingress.NginxIngressController( nginxValues );
}