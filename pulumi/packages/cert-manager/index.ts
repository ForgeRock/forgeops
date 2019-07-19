import * as k8s from "@pulumi/kubernetes";
import * as gcp from "@pulumi/gcp";
import { ConfigFile, ConfigGroup } from "@pulumi/kubernetes/yaml";

/**
 * cert-manager configuration values
 */
export interface ChartArgs {

    // TLS key and secret for cert-manager ca(self-signed) certificate
    tlsKey: string;
    tlsCrt: string;

    // The cluster provider containing the kubeconfig
    clusterProvider: k8s.Provider;

    // Cloud DNS Service Account
    cloudDnsSa: string;

    nodePoolDependency: gcp.container.NodePool;
}

/**
 * cert-manager used in ForgeRock CDM samples deployed by Pulumi
 */
export class CertManager {

    readonly certmanagerResources: ConfigFile
    readonly caSecret: k8s.core.v1.Secret
    readonly clouddns: k8s.core.v1.Secret
    readonly cmIssuers: ConfigGroup

    /**
    * Deploy Nginx Ingress Controller to k8s cluster.
    * @param name  The _unique_ name of the resource.
    * @param chartArgs  The values to configure Nginx Controller Helm chart.
    * @param opts  A bag of options that control this resource's behavior.
    */

    constructor(chartArgs: ChartArgs) {

        // Deploy cert-manager
        this.certmanagerResources = new ConfigFile("cmResources", {
            file: "https://github.com/jetstack/cert-manager/releases/download/v0.8.1/cert-manager.yaml", 
        },{ dependsOn: chartArgs.nodePoolDependency, provider: chartArgs.clusterProvider });

        // Deploy secret - certificate for cert-manager ca certificate(self signed)
        this.caSecret = new k8s.core.v1.Secret("certmanager-ca-secret",{
            metadata: {
                name: "certmanager-ca-secret", 
                namespace: "cert-manager"
            },
            type: "kubernetes.io/tls",
            stringData: {
                "tls.key": chartArgs.tlsKey,
                "tls.crt": chartArgs.tlsCrt
            }
        },{ dependsOn: [this.certmanagerResources], provider: chartArgs.clusterProvider});

        // Deploy secret - service account for access to Cloud DNS
        this.clouddns = new k8s.core.v1.Secret("clouddns",{
            metadata: {
                name: "clouddns",
                namespace: "cert-manager"
            },
            type: "Opaque",
            stringData: {
                "cert-manager.json": chartArgs.cloudDnsSa
            }
        },{ dependsOn: [this.certmanagerResources], provider: chartArgs.clusterProvider });

         // Deploy cert-manager issuers
        this.cmIssuers = new ConfigGroup("certManager", {
            files: [
                'files/ca-issuer.yaml',
                'files/le-issuer.yaml'
            ]
        },{ dependsOn: [this.certmanagerResources], provider: chartArgs.clusterProvider });
    }
}






