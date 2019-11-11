import * as cluster from "./cluster";
import * as nginx from "./nginx-controller";

// Static IP
export const ip = nginx.nginxValues.ip;

export const kubeconfig = cluster.k8sCluster.kubeConfigRaw;


const certmanager = cluster.createCertManager(cluster.k8sProvider)
