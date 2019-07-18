import * as k8s from "@pulumi/kubernetes";
/**
 * Nginx Ingress Controller configuration values
 */
export interface ChartArgs {
    ip: string;
    version: string;
    clusterProvider: k8s.Provider;
    namespace: string;
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
