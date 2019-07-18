import * as k8s from "@pulumi/kubernetes";

/** 
 * Nginx Ingress Controller Helm chart
 */ 
function nginxChart(ip: string, version: string, ns: string, clusterProvider: k8s.Provider, metaNs: any) {
    
    const nginx = new k8s.helm.v2.Chart("nginx-ingress", {
        repo: "stable",
        version: version,
        chart: "nginx-ingress",
        transformations: [metaNs],
        namespace: ns,
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
    }, { provider: clusterProvider });

    return nginx;
}

/**
 * Nginx Ingress Controller configuration values
 */
export interface ChartArgs {
    // Static IP address
    ip: string;

    // Nginx version for Ingress Controller
    version: string;

    // The cluster provider containing the kubeconfig
    clusterProvider: k8s.Provider;

    // Namespace
    namespace: string;
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
        const ns = chartArgs.namespace;

        function metaNamespace(o: any) {
            if (o !== undefined) {
                o.metadata.namespace = ns;
            }
        }

        const nginx = nginxChart(ip, version, ns, clusterProvider, metaNamespace);

        return nginx;
    }
}






