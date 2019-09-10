import { Config } from "@pulumi/pulumi";
import * as cluster from "./cluster";
import * as cm from "../packages/cert-manager"

// Get access to stack configuration values
const config = new Config();

// Define cert-manager values
const certManagerValues: cm.ChartArgs = {
    tlsKey: config.require("tls-key"),
    tlsCrt: config.require("tls-crt"),
    clusterProvider: cluster.k8sProvider,
    cloudDnsSa: config.require("clouddns"),
    dependency: cluster.k8sProvider
}

// Deploy cert-manager
export const certManager = new cm.CertManager(certManagerValues);
