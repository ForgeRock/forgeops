import * as k8s from "@pulumi/kubernetes";
import { cluster } from "./cluster";
import * as pulumi from "@pulumi/pulumi";
import { nginxVersion, route53Domain } from "./config";
import * as ingressController from "../packages/nginx-ingress-controller";
import { prodNs } from "./index";
//import { route53 } from "@pulumi/aws";

// Create nginx namespace
// export const nsnginx = new k8s.core.v1.Namespace("nginx", { 
//     metadata: { 
//         name: "nginx" 
//     }
// }, { dependsOn: [ cluster ], provider: cluster.provider });

const awsNlb = {"service\.beta\.kubernetes\.io/aws-load-balancer-type": "nlb"};

const url: pulumi.Output<string> = pulumi.concat(prodNs,".iam.",route53Domain)

// Set values for nginx Helm chart
const nginxValues: ingressController.ChartArgs = {
    version: nginxVersion,
    clusterProvider: cluster.provider,
    dependency: cluster,
    //namespace: nsnginx,
    annotations: awsNlb,
    domain: route53Domain,
    url: url
}

// Deploy Nginx Ingress Controller Helm chart
export const nginxControllerChart = new ingressController.NginxIngressController( nginxValues );

