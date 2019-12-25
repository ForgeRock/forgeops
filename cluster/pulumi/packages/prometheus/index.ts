import * as k8s from "@pulumi/kubernetes";

export interface PkgArgs {
    version: string;
    namespaceName: string;
    k8sVersion: string;
    provider: k8s.Provider;
    dependsOn: any[];
    enableExternal?: boolean;
    hostname?: string;
}


export class Prometheus {

    readonly version: string
    readonly provider: k8s.Provider
    private namespaceName: string
    readonly namespace: k8s.core.v1.Namespace
    readonly hostname: string
    readonly enableExternal: boolean

    /**
    * Deploy Prometheus to k8s cluster.
    * @param PkgArgs  Args for Prometheus
    */

    constructor(args: PkgArgs) {
        this.version = args.version;
        //this.provider = args.cluster.provider;
        this.provider = args.provider;
        this.namespaceName = args.namespaceName;

        const namespace = new k8s.core.v1.Namespace("prometheusNamespace", {
            metadata: {
                name: this.namespaceName
            }}, 
            {provider: args.provider, dependsOn:args.dependsOn})

        this.namespace = namespace;
        
        // Set external hostname for ingress
        if (args.hostname) {
            this.hostname = args.hostname;
        }

        if (args.enableExternal) {
            this.enableExternal = args.enableExternal;
        }


        // function to add ingress block for external access
        function addExternalAccess(hostname: string, path: string) {

            // set annotations for ingress
            let annotations = {
                "kubernetes.io/ingress.class" : "nginx",
                "certmanager.k8s.io/cluster-issuer": "default-issuer",
                "nginx.ingress.kubernetes.io/ssl-redirect": "true"
            }

            return {
                    enabled: true,
                    annotations: { annotations },
                    hosts: [ hostname ],
                    paths: [ path ],
                    tls: [
                        {
                            secretName: "sslcert",
                            hosts: [ hostname ]
                        }
                    ]
            }       
        }

        function addNamespace (o: any): void{
            if (o !== undefined) {
                if (o.metadata !== undefined) {
                    if (o.metadata.name.toLowerCase().includes("coredns") || o.metadata.name.toLowerCase().includes("kube-proxy")){
                        o.metadata.namespace = "kube-system"
                    } else {
                        o.metadata.namespace = args.namespaceName;
                    }
                } else {
                    o.metadata = {namespace: args.namespaceName};
                }
            }
            //Allow grafana test pod to retry if grafana pod is not ready yet.
            //this would allow to skip the test pod altogether: https://github.com/pulumi/pulumi-kubernetes/pull/666
            if (o.kind.toLowerCase() == "pod" && o.metadata.name.toLowerCase().includes("grafana-test")){
                o.spec.restartPolicy = "OnFailure"
            }
        }

        //Deploy the Prometheus Operator to the cluster
        const prometheusOperator = new k8s.helm.v2.Chart("promhelm", {
            repo: "stable",
            version: this.version,
            namespace: this.namespaceName,
            chart: "prometheus-operator",
            transformations: [addNamespace],
            values: {
                kubeTargetVersionOverride: args.k8sVersion,
                alertmanager: {
                    enabled: true,
                    // required if configuring ingress block
                    alertmanagerSpec: this.enableExternal ? { routePrefix: "/alertmanager" } : {},
                    // Add ingress block if external access requested
                    ingress: this.enableExternal ? addExternalAccess(this.hostname, "/alertmanager") : {}
                },
                grafana: {
                    enabled: true,
                    adminPassword: "password",
                    // Add ingress block if external access requested
                    ingress: this.enableExternal ? addExternalAccess(this.hostname, "grafana") : {}, 
                },
                defaultRules: {
                    create: true,
                    rules: {
                        etcd: false,
                        kubeApiserver: false,
                        kubeScheduler: false,
                        kubernetesSystem: false, //TODO: Need to create kube node not ready as a custom rule
                    }
                },
                coreDns: {
                    enabled: true,
                },
                kubeEtcd: {
                    enabled: false,
                },
                kubeScheduler: {
                    enabled: false,
                },
                kubeControllerManager: {
                    enabled: false,
                },
                kubeProxy: {
                    //Disabled by default. EKS deploys kubeproxy with bound to 127.0.0.1. Can't scrape /metrics endpoint by default.
                    // to enable this, edit the configmap `kube-proxy-config` in the kube-system ns and change the metrics binding to 0.0.0.0
                    enabled: false,
                },
                "kube-state-metrics": {
                    enabled: false,
                    podSecurityPolicy: {
                        enabled: false,
                    },
                },
                prometheus: {
                    service: {
                        type: "ClusterIP",
                    },
                    prometheusSpec:{
                        //match any rule and any serviceMonitor on any namespace
                        serviceMonitorSelectorNilUsesHelmValues: false,
                        ruleSelectorNilUsesHelmValues: false,
                        // required if configuring ingress block
                        routePrefix: this.enableExternal ? "/prometheus" : "",
                    },
                    // Add ingress block if external access requested
                    ingress: this.enableExternal ? addExternalAccess(this.hostname, "/prometheus") : {}, 
                },
                prometheusOperator: {
                    createCustomResource: false,
                },
            },
        }, {provider:  args.provider, dependsOn: [namespace].concat(args.dependsOn)});

        const forgerockMetrics = new k8s.helm.v2.Chart("forgerock-metrics", {
            path: "../../packages/prometheus/forgerock-metrics",
            namespace: this.namespaceName,
            transformations: [addNamespace],
            values: {
                am: {
                    port: "am",
                    labelSelectorComponent: "am"
                },
                ds: {
                    port: "http",
                    labelSelectorComponent: "ds"
                },
                idm: {
                    port: "idm",
                    enabled: true,
                    labelSelectorComponent: "idm"
                },
                ig: {
                    enabled: false
                }
            }
        }, {provider:  args.provider, dependsOn: [namespace, prometheusOperator].concat(args.dependsOn)});
    }
}