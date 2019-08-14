import * as k8s from "@pulumi/kubernetes";
import * as pulumi from "@pulumi/pulumi";

/** 
 * Nginx Ingress Controller Helm chart
 */ 
function nginxChart(ip: string, version: string, clusterProvider: k8s.Provider, metaNs: any, dependencies: any[], ns: k8s.core.v1.Namespace, annotations: any) {
    
    const nginx = new k8s.helm.v2.Chart("nginx-ingress", {
        fetchOpts: {
            repo: "https://kubernetes-charts.storage.googleapis.com",
            version: version
        },
        version: "1.9.1",
        chart: "nginx-ingress",
        transformations: [metaNs],
        namespace: ns.metadata.name,
        values: {
            rbac: {create: true},
            controller: {
                publishService: {enabled: true},
                stats: {
                    enabled: true,
                    service: { omitClusterIP: true } 
                },
                service: {
                    type: "LoadBalancer",
                    externalTrafficPolicy: "Local",
                    loadBalancerIP: ip,
                    annotations: annotations,
                    omitClusterIP: true
                },
                image: {tag: version}
            },
            defaultBackend: {
                service: { omitClusterIP: true }
            }
        }
    },{dependsOn: dependencies, provider:  clusterProvider});

    return nginx;
}

// function addRoute53Record(domain: string, nginx: k8s.helm.v2.Chart, url: pulumi.Output<string>) {

//     // Get the hostname given to the ingress load balancer
//     const hostname = nginx.getResource("v1/Service", "nginx-ingress-controller").status.apply(s => s.loadBalancer.ingress[0].hostname);

//     // Get the hosted zone details from the provided domain
//     const selected = pulumi.output(aws.route53.getZone({
//         name: domain
//     }));

//     // Upsert new CNAME record into hosted domain
//     new aws.route53.Record("www", {
//         name: url,
//         records: [hostname],
//         ttl: 300,
//         type: "CNAME",
//         zoneId: selected.zoneId,
//     });
// }

/**
 * Nginx Ingress Controller configuration values
 */
export interface ChartArgs {
    // Static IP address
    ip?: pulumi.Output<string>;

    // Nginx version for Ingress Controller
    version: string;

    // The cluster provider containing the kubeconfig
    clusterProvider: k8s.Provider;

    // Dependency to force wait for cluster build
    dependencies: any[];

    // Namespace
    //namespace: k8s.core.v1.Namespace;

    // Any required annotation
    annotations?: any;

    // For creating route53 records
    domain?: string; 
    url?: pulumi.Output<string>;
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
        
        let ip = chartArgs.ip;
        const version = chartArgs.version;
        const clusterProvider = chartArgs.clusterProvider;
        const dependencies = chartArgs.dependencies;
        //const ns = chartArgs.namespace;
        const annotations = chartArgs.annotations;
        const domain = chartArgs.domain;
        const url = chartArgs.url;
        let staticIp: any;
        // let dependencies: any = [ dependency ];

        // // Create array of dependencies
        // dependencies.push(ip) 

        // Create nginx namespace
        const ns = new k8s.core.v1.Namespace("nginx", { 
            metadata: { 
                name: "nginx" 
            }
        }, { dependsOn: dependencies, provider: clusterProvider });

        // set namespace field in k8s manifest after Helm chart as been transformed.
        function metaNamespace(o: any) {
            if (o !== undefined) {
                o.metadata.namespace = ns.metadata.name;
            }
        }

        // Check if IP has been provided and convert from Output<string>
        if ( ip !== undefined ) {
            staticIp = ip.apply(i => i);
        };

        
        // Deploy Ingress Controller Helm chart
        const nginx = nginxChart(staticIp, version, clusterProvider, metaNamespace, dependencies, ns, annotations);

        //addRoute53Record(domain, nginx, url);

        return nginx;
    }
}




