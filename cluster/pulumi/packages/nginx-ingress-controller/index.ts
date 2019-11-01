import * as k8s from "@pulumi/kubernetes";
import * as pulumi from "@pulumi/pulumi";

/**
 * Nginx Ingress Controller configuration values
 */
export interface PkgArgs {
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

    // A partial or complete values object for the helm chart
    helmValues?: object;

}

/**
 * Nginx Ingress Controller used for deploying ForgeRock CDM samples with Pulumi
 */
export class NginxIngressController extends k8s.helm.v2.Chart {

    /**
    * Deploy Nginx Ingress Controller to k8s cluster.
    * @param name  The _unique_ name of the resource.
    * @param PkgArgs  The values to configure Nginx Controller Helm chart.
    * @param opts  A bag of options that control this resource's behavior.
    */

    constructor(chartArgs: PkgArgs) {
        let ip = chartArgs.ip;
        let version = chartArgs.version;
        let clusterProvider = chartArgs.clusterProvider;
        let dependencies = chartArgs.dependencies;
        //const ns = chartArgs.namespace;
        let annotations = chartArgs.annotations;
        let staticIp: any;
        let buildHelmValues = (suppliedValues: object) => {
            const defaultValues = {
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
                },
                defaultBackend: {
                  service: { omitClusterIP: true }
                }
            }
            if (!suppliedValues) {
                suppliedValues = {}
            }
            return {...defaultValues, ...suppliedValues}
        }
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
            ip = ip.apply(i => i);
        };
        super("nginx-ingress", {
           version: chartArgs.version, // TODO not sure what this version is for, the chart?
           chart: "nginx-ingress",
           repo: "stable",
           transformations: [metaNamespace],
           namespace: ns.metadata.name,
           values: buildHelmValues(chartArgs.helmValues || {}),
        },{dependsOn: dependencies, provider: clusterProvider})
    }
}
