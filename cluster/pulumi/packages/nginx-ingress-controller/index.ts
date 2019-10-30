import * as k8s from "@pulumi/kubernetes";
import * as eks from "@pulumi/eks";

export interface PkgArgs {
    version: string;
    namespaceName: string;
    cluster: eks.Cluster;
    dependsOn: any[];
}

export class NginxIngressController {

    readonly version: string
    readonly provider: k8s.Provider
    private namespacename: string
    readonly namespace: k8s.core.v1.Namespace

    /**
    * Deploy Nginx Ingress Controller to k8s cluster.
    * @param PkgArgs  Args for NginxIngressController
    */

    constructor(args: PkgArgs) {

        this.version = args.version;
        this.provider = args.cluster.provider;
        this.namespacename = args.namespaceName;

        const namespace = new k8s.core.v1.Namespace("ingressNamespace", {
            metadata: {
                name: this.namespacename
            }}, 
            {provider: args.cluster.provider, dependsOn:args.dependsOn})
        this.namespace = namespace;
            
        const nginx = new k8s.helm.v2.Chart("nginx-ingress", {
            version: args.version,
            chart: "nginx-ingress",
            repo: "stable",
            transformations: [(o: any) => { if (o !== undefined) { o.metadata.namespace = this.namespacename}}],
            namespace: this.namespacename,
            values: {
                rbac: {create: true},
                controller: {
                    kind: "DaemonSet",
                    daemonset: {
                        useHostPort: true,
                        hostPorts: {
                            http: 30080,
                            https: 30443,
                        }
                    },
                    tolerations: [{
                        key: "WorkerAttachedToExtLoadBalancer",
                        operator: "Exists",
                        effect: "NoSchedule",
                        }
                    ],
                    nodeSelector: {"frontend": "true"},
                    publishService: {enabled: true},
                    stats: {
                        enabled: true,
                        service: { omitClusterIP: true } 
                    },
                    service: {
                        enabled: false,
                        type: "ClusterIP",
                        omitClusterIP: true,
                    },
                },
                defaultBackend: {
                    enabled: false,
                }
            }
        },{provider:  args.cluster.provider, dependsOn: [namespace].concat(args.dependsOn)});
    }
 }
