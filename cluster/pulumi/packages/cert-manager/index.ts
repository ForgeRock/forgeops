import * as k8s from "@pulumi/kubernetes";
import * as eks from "@pulumi/eks";
import * as pulumi from "@pulumi/pulumi";
const Client = require('kubernetes-client').Client

export interface PkgArgs {
    version: string;
    useSelfSignedCert: boolean;
    tlsKey: string; //TLS key to be use when selfSignedCert
    tlsCrt: string; //TLS Cert to be use when selfSignedCert
    cloudDnsSa: string; // Cloud DNS Service Account
    clusterProvider: k8s.Provider;
    dependsOn: any[];
}

export class CertManager {

    readonly certmanagerResources: k8s.yaml.ConfigFile
    readonly version: string
    readonly provider: k8s.Provider
    readonly issuerSecret: k8s.core.v1.Secret
    /**
    * Deploy cert-manager to k8s cluster.
    * @param PkgArgs  Args for CertManager
    */

    constructor(args: PkgArgs) {

        this.version = args.version;
        this.provider = args.clusterProvider;

        // Deploy cert-manager
        const certmanagerResources = new k8s.yaml.ConfigFile("cmResources", {
            file: `https://github.com/jetstack/cert-manager/releases/download/${args.version}/cert-manager.yaml`,
        },{ dependsOn: args.dependsOn, provider: this.provider });
        this.certmanagerResources = certmanagerResources;

        let yamlFiles : string[]= [];
        if (args.useSelfSignedCert){
            yamlFiles.push('../../packages/cert-manager/files/ca-issuer.yaml'); //TODO: Need to base relative path from location of lib

            //Deploy secret - certificate for cert-manager ca certificate(self signed)
            const caSecret = new k8s.core.v1.Secret("certmanager-ca-secret",{
                metadata: {
                    name: "certmanager-ca-secret",
                    namespace: "cert-manager"
                },
                type: "kubernetes.io/tls",
                stringData: {
                    "tls.key": args.tlsKey,
                    "tls.crt": args.tlsCrt
                }
            },{dependsOn: [this.certmanagerResources], provider: this.provider});
            this.issuerSecret = caSecret;
        }
        else{
            yamlFiles.push('../../packages/cert-manager/files/le-issuer.yaml'); //TODO: Need to base relative path from location of lib

            // Deploy secret - service account for access to Cloud DNS
            const clouddns = new k8s.core.v1.Secret("clouddns",{
                metadata: {
                    name: "clouddns",
                    namespace: "cert-manager"
                },
                type: "Opaque",
                stringData: {
                    "cert-manager.json": args.cloudDnsSa
                }
            },{dependsOn: [this.certmanagerResources], provider: this.provider });
            this.issuerSecret = clouddns;
        }

        const webhookDeployment = this.certmanagerResources.getResource("apps/v1/Deployment", "cert-manager", "cert-manager-webhook")
        const cmIssuers = new k8s.yaml.ConfigGroup("certManagerIssuers", {
            files: yamlFiles,
            transformations: [(o: any) => {o.metadata.namespace = "cert-manager"}],
            },{ dependsOn: webhookDeployment, provider: this.provider, customTimeouts: { create: "3m" }});
    }

}
