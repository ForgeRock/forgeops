import * as k8s from "@pulumi/kubernetes";
import * as gcp from "@pulumi/gcp";
import * as pulumi from "@pulumi/pulumi";
/**
 * Nginx Ingress Controller configuration values
 */
export interface ChartArgs {
    ip: pulumi.Output<string>;
    version: string;
    clusterProvider: k8s.Provider;
    nodePool: gcp.container.NodePool;
    namespace: k8s.core.v1.Namespace;
}
/**
 * Nginx Ingress Controller used for deploying ForgeRock CDM samples with Pulumi
 */
export declare class NginxIngressController {
    /**
    * Deploy Nginx Ingress Controller to k8s cluster.
    * @param name  The _unique_ name of the resource.
    * @param chartArgs  The values to configure Nginx Controller Helm chart.
    * @param opts  A bag of options that control this resource's behavior.
    */
    constructor(chartArgs: ChartArgs);
}
