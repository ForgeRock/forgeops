import * as k8s from "@pulumi/kubernetes";
import * as pulumi from "@pulumi/pulumi";
import { ConfigFile, ConfigGroup } from "@pulumi/kubernetes/yaml";
/**
 * cert-manager configuration values
 */
export interface ChartArgs {
    tlsKey: string;
    tlsCrt: string;
    clusterProvider: k8s.Provider;
    cloudDnsSa: string;
}
/**
 * cert-manager used in ForgeRock CDM samples deployed by Pulumi
 */
export declare class CertManager {
    readonly certmanagerResources: ConfigFile;
    readonly caSecret: k8s.core.v1.Secret;
    readonly clouddns: k8s.core.v1.Secret;
    readonly cmIssuers: ConfigGroup;
    /**
    * Deploy Nginx Ingress Controller to k8s cluster.
    * @param name  The _unique_ name of the resource.
    * @param chartArgs  The values to configure Nginx Controller Helm chart.
    * @param opts  A bag of options that control this resource's behavior.
    */
    constructor(name: string, chartArgs: ChartArgs, opts?: pulumi.ResourceOptions);
}
