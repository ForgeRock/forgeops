import * as k8s from "@pulumi/kubernetes";
import { clusterProvider } from "./cluster";
import { nginx } from "./nginx-controller";
import { certmanager } from "./cert-manager";

// Create Prometheus namespace
const nsprometheus = new k8s.core.v1.Namespace("prometheus", { metadata: { name: "prometheus" }}, { dependsOn: [nginx,certmanager],provider: clusterProvider });

// Define namespace field for Helm chart
function addNamespace(o: any) {
    if (o !== undefined) {
        o.metadata.namespace = nsprometheus;
    }
}

// Deploy Prometheus Operator
const prometheusOperator = new k8s.helm.v2.Chart("prometheus-operator", {
    repo: "stable",
    //version: "0.31.1",
    chart: "prometheus-operator",
    transformations: [addNamespace],
    namespace: "prometheus",
    values: {
        rbac: {create: true},
        kubeScheduler: {enabled: false},
        kubeControllerManager: {enabled: false},
        kubeEtcd: {enabled: false},
        coreDns: {enabled: false},
        kubeStateMetrics: {enabled: false},
        kubeApiServer: {enabled: false}
        // serviceMonitorsSelector: {
        //     matchExpressions: [
        //     {
        //         key: "app",
        //         operator: "In",
        //         values: ["am","ds","idm"]
        //     }]
        // }
    }
}, { dependsOn: [nsprometheus], provider: clusterProvider });




