import * as cluster from "./cluster";
import * as nginx from "./nginx-controller";
import "./cert-manager";

// Static IP
export const ip = nginx.nginxValues.ip;

// Kubeconfig
export const kubeconfig = cluster.k8sCluster.kubeConfigRaw;
