import * as k8s from "@pulumi/kubernetes";
import * as gcp from "@pulumi/gcp";
import * as pulumi from "@pulumi/pulumi";

/** 
 * Nginx Ingress Controller Helm chart
 */ 
function nginxChart(ip: pulumi.Output<string>, version: string, clusterProvider: k8s.Provider, metaNs: any, nodePool: gcp.container.NodePool, ns: k8s.core.v1.Namespace) {
    
    const nginx = new k8s.helm.v2.Chart("nginx-ingress", {
        repo: "stable",
        version: version,
        chart: "nginx-ingress",
        transformations: [metaNs],
        namespace: ns.metadata.name,
        values: {
            rbac: {create: true},
            controller: {
                publishService: {enabled: true},
                stats: {enabled: true},
                service: {
                    type: "LoadBalancer",
                    externalTrafficPolicy: "Local",
                    loadBalancerIP: ip
                },
                image: {tag: version}
            }
        }
    },{dependsOn: [nodePool, ns], provider:  clusterProvider});

    return nginx;
}

/**
 * Nginx Ingress Controller configuration values
 */
export interface ChartArgs {
    // Static IP address
    ip: pulumi.Output<string>;

    // Nginx version for Ingress Controller
    version: string;

    // The cluster provider containing the kubeconfig
    clusterProvider: k8s.Provider;

    nodePool: gcp.container.NodePool;

    // Namespace
    namespace: k8s.core.v1.Namespace;
}

/**
 * Nginx Ingress Controller used for deploying ForgeRock CDM samples with Pulumi
 */
export class NginxIngressController {

    /**
    * Deploy Nginx Ingress Controller to k8s cluster.
    * @param name  The _unique_ name of the resource.
    * @param chartArgs  The values to configure Nginx Controller Helm chart.
    * @param opts  A bag of options that control this resource's behavior.
    */

    constructor(chartArgs: ChartArgs) {
        
        const ip = chartArgs.ip;
        const version = chartArgs.version;
        const clusterProvider = chartArgs.clusterProvider;
        const nodePool = chartArgs.nodePool;
        const ns = chartArgs.namespace;

        // set namespace field in k8s manifest after Helm chart as been transformed.
        function metaNamespace(o: any) {
            if (o !== undefined) {
                o.metadata.namespace = ns.metadata.name;
            }
        }

        // Deploy Ingress Controller Helm chart
        const nginx = nginxChart(ip, version, clusterProvider, metaNamespace, nodePool, ns);

        return nginx;
    }
}






