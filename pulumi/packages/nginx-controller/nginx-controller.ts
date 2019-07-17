import * as k8s from "@pulumi/kubernetes";
import * as pulumi from "@pulumi/pulumi";

//import { ConfigFile, ConfigGroup } from "@pulumi/kubernetes/yaml";
//import { Config } from "@pulumi/pulumi";
//import { clusterProvider, primaryPool } from "./cluster";
//import { nsnginx } from "./nginx-controller"

//const config = new Config();

function nginxNamespace() {
    const nsnginx = new k8s.core.v1.Namespace("nginx", { 
        metadata: { 
            name: "nginx" 
        }
    }, { dependsOn: [ primaryPool ], provider: clusterProvider });   
}

// Adds namespace to correct Helm field
function metaNamespace(o: any) {
    if (o !== undefined) {
        o.metadata.namespace = "nginx";
    }
}

function nginxChart(ip: string, version: string, clusterProvider: pulumi.ProviderResource, namespace: string) {
    // Deploy nginx-controller Helm chart
    const nginx = new k8s.helm.v2.Chart("nginx-ingress", {
        repo: "stable",
        version: version,
        chart: "nginx-ingress",
        transformations: [metaNamespace],
        namespace: "nginx",
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
}

/**
 * Arguments to StaticWebsite concerning the website's contents.
 */
export interface ChartArgs {
    /**
     * Path to the content files to serve relative to the CWD of the Pulumi program.
     */
    ip: string;

    /**
     * Path to the resource to serve if the CDN fails to locate the intended
     * resource.
     */
    version: string;

    clusterProvider: pulumi.ProviderResource

    nginxNamespace: string;
}

/**
 * Static website using Amazon S3, CloudFront, and Route53.
 */
export class ForgerockNginxController extends pulumi.ComponentResource  {
    // readonly contentBucket: aws.s3.Bucket;
    // readonly logsBucket: aws.s3.Bucket;
    // readonly cdn: aws.cloudfront.Distribution;
    // readonly aRecord?: aws.route53.Record;

    /**
    * Creates a new static website hosted on AWS.
    * @param name  The _unique_ name of the resource.
    * @param chartValues  The values to configure Nginx Controller Helm chart.
    * @param opts  A bag of options that control this resource's behavior.
    */

    constructor(name: string , chartArgs: ChartArgs, opts?: pulumi.ResourceOptions) {
        const inputs: pulumi.Inputs = {
            options: opts,
        };
        super("pulumi-contrib:components:ForgerockNginxController", name, inputs, opts);

        // Default resource options for this component's child resources.
        //const defaultResourceOptions: pulumi.ResourceOptions = { parent: this };
        
        const ip = chartArgs.ip;
        const version = chartArgs.version;
        const clusterProvider = chartArgs.clusterProvider;
        const nginxNamespace = chartArgs.nginxNamespace;

        nginxChart(ip, version, clusterProvider, nginxNamespace);
    }
}






