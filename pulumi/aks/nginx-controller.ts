import * as k8s from "@pulumi/kubernetes";
import * as cluster from "./cluster";
import * as pulumi from "@pulumi/pulumi";
import * as config from "./config";
import * as ingressController from "../packages/nginx-ingress-controller";
import { statIp, ipGroup } from "./index";
//import { prodNs } from "./index";

const azLbType = {"service\.beta\.kubernetes\.io/azure-load-balancer-resource-group": "aks-small-ip-resource-group"};

// Set values for nginx Helm chart
const nginxValues: ingressController.ChartArgs = {
    ip: statIp,
    version: config.nginxVersion,
    clusterProvider: cluster.k8sProvider,
    dependency: cluster.k8sCluster,
    annotations: azLbType
};

// Deploy Nginx Ingress Controller Helm chart
export const nginxControllerChart = new ingressController.NginxIngressController( nginxValues );

