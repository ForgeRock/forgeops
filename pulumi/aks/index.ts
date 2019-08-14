import * as pulumi from "@pulumi/pulumi";
import * as azure from "@pulumi/azure";
import * as cluster from "./cluster";
import * as config from "./config";
import "./nginx-controller";
import { nginxValues } from "./nginx-controller";

export const ip = nginxValues.ip;

// Expose a K8s provider instance using our custom cluster instance.
export const kubeconfig = cluster.k8sCluster.kubeConfigRaw;
