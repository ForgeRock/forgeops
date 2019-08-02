import * as k8s from "@pulumi/kubernetes";
import { cluster } from "./cluster";
import * as pulumi from "@pulumi/pulumi";
import { nginxVersion, route53Domain } from "./config";
import * as ingressController from "../packages/nginx-ingress-controller";
import { prodNs } from "./index";

const awsNlb = {"service\.beta\.kubernetes\.io/aws-load-balancer-type": "nlb"};

const url: pulumi.Output<string> = pulumi.concat(prodNs,".iam.",route53Domain)

// Set values for nginx Helm chart
const nginxValues: ingressController.ChartArgs = {
    version: nginxVersion,
    clusterProvider: cluster.provider,
    dependency: cluster,
    annotations: awsNlb,
    domain: route53Domain,
    url: url
}

// Deploy Nginx Ingress Controller Helm chart
export const nginxControllerChart = new ingressController.NginxIngressController( nginxValues );

