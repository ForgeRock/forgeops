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
    clusterKubeconfig: pulumi.Output<any>;
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

        //wait until CM deployment is healthy before creating cluster issuer.
        args.clusterKubeconfig.apply(kc => this.waitForDeployment(kc, "cert-manager", "cert-manager-webhook", yamlFiles, [certmanagerResources, this.issuerSecret]))

    }

    private async waitForDeployment(kc: pulumi.Output<any>, namespace: string, name: string, yamlFiles: string[], dependsOn: any[]): Promise<any> {
        if (!pulumi.runtime.isDryRun()) {
            const { KubeConfig } = require('kubernetes-client');
            const kubeconfig = new KubeConfig();
            kubeconfig.loadFromString(JSON.stringify(kc));
            const Request = require('kubernetes-client/backends/request');
            const backend = new Request({ kubeconfig });
            const client = new Client({ backend, version: '1.13' })
            //wait for 30 seconds to allow initial pass/fail in the deployment
            await new Promise(r => setTimeout(r, 30000));
            // Wait for up to 3 minutes
            for (let i = 0; i < 6; i++) {
                try {
                    const deployment = await client.apis.apps.v1.namespace(namespace).deployment(name).get();
                    if (deployment.body && deployment.body.status && deployment.body.status.readyReplicas && deployment.body.status.availableReplicas > 0) {
                        // console.log(deployment.body)
                        //////////////////////////////////////////////////////////////////

                        //////////////////////////////////////////////////////////////////
                        break;
                    }
                }
                catch(e) {
                    pulumi.log.info(`Waiting for Deployment to become healthy`);
                }
                // Wait for 10s between polls
                await new Promise(r => setTimeout(r, 10000));
            }
            const cmIssuers = new k8s.yaml.ConfigGroup("certManagerIssuers", {
                files: yamlFiles,
                transformations: [(o: any) => {o.metadata.namespace = "cert-manager"}],
            },{ dependsOn: dependsOn, provider: this.provider });
            //throw new Error("Timed out: Waiting for Deployment to become healthy");
        }
    }
}
