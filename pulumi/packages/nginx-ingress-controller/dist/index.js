"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var k8s = require("@pulumi/kubernetes");
/**
 * Nginx Ingress Controller Helm chart
 */
function nginxChart(ip, version, clusterProvider, metaNs, nodePool, ns) {
    var nginx = new k8s.helm.v2.Chart("nginx-ingress", {
        repo: "stable",
        version: version,
        chart: "nginx-ingress",
        transformations: [metaNs],
        namespace: ns.metadata.name,
        values: {
            rbac: { create: true },
            controller: {
                publishService: { enabled: true },
                stats: { enabled: true },
                service: {
                    type: "LoadBalancer",
                    externalTrafficPolicy: "Local",
                    loadBalancerIP: ip
                },
                image: { tag: version }
            }
        }
    }, { dependsOn: [nodePool, ns], provider: clusterProvider });
    return nginx;
}
/**
 * Nginx Ingress Controller used for deploying ForgeRock CDM samples with Pulumi
 */
var NginxIngressController = /** @class */ (function () {
    /**
    * Deploy Nginx Ingress Controller to k8s cluster.
    * @param name  The _unique_ name of the resource.
    * @param chartArgs  The values to configure Nginx Controller Helm chart.
    * @param opts  A bag of options that control this resource's behavior.
    */
    function NginxIngressController(chartArgs) {
        var ip = chartArgs.ip;
        var version = chartArgs.version;
        var clusterProvider = chartArgs.clusterProvider;
        var nodePool = chartArgs.nodePool;
        var ns = chartArgs.namespace;
        // set namespace field in k8s manifest after Helm chart as been transformed.
        function metaNamespace(o) {
            if (o !== undefined) {
                o.metadata.namespace = ns.metadata.name;
            }
        }
        // Deploy Ingress Controller Helm chart
        var nginx = nginxChart(ip, version, clusterProvider, metaNamespace, nodePool, ns);
        return nginx;
    }
    return NginxIngressController;
}());
exports.NginxIngressController = NginxIngressController;
