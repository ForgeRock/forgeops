"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var k8s = require("@pulumi/kubernetes");
var yaml_1 = require("@pulumi/kubernetes/yaml");
/**
 * cert-manager used in ForgeRock CDM samples deployed by Pulumi
 */
var CertManager = /** @class */ (function () {
    /**
    * Deploy Nginx Ingress Controller to k8s cluster.
    * @param name  The _unique_ name of the resource.
    * @param chartArgs  The values to configure Nginx Controller Helm chart.
    * @param opts  A bag of options that control this resource's behavior.
    */
    function CertManager(name, chartArgs, opts) {
        var inputs = {
            options: opts,
        };
        //super("pulumi-contrib:components:CertManager", name, inputs, opts);
        // Default resource options for this component's child resources.
        //const defaultResourceOptions: pulumi.ResourceOptions = { parent: this };
        // Deploy cert-manager
        this.certmanagerResources = new yaml_1.ConfigFile("cmResources", {
            file: "https://github.com/jetstack/cert-manager/releases/download/v0.8.1/cert-manager.yaml",
        }, { provider: chartArgs.clusterProvider });
        // Deploy secret - certificate for cert-manager ca certificate(self signed)
        this.caSecret = new k8s.core.v1.Secret("certmanager-ca-secret", {
            metadata: {
                name: "certmanager-ca-secret",
                namespace: "cert-manager"
            },
            type: "kubernetes.io/tls",
            stringData: {
                "tls.key": chartArgs.tlsKey,
                "tls.crt": chartArgs.tlsCrt
            }
        }, { dependsOn: [this.certmanagerResources], provider: chartArgs.clusterProvider });
        // Deploy secret - service account for access to Cloud DNS
        this.clouddns = new k8s.core.v1.Secret("clouddns", {
            metadata: {
                name: "clouddns",
                namespace: "cert-manager"
            },
            type: "Opaque",
            stringData: {
                "cert-manager.json": chartArgs.cloudDnsSa
            }
        }, { dependsOn: [this.certmanagerResources], provider: chartArgs.clusterProvider });
        // Deploy cert-manager issuers
        this.cmIssuers = new yaml_1.ConfigGroup("certManager", {
            files: [
                'files/ca-issuer.yaml',
                'files/le-issuer.yaml'
            ]
        }, { dependsOn: [this.certmanagerResources], provider: chartArgs.clusterProvider });
    }
    return CertManager;
}());
exports.CertManager = CertManager;
