import { Config } from "@pulumi/pulumi";
import { cluster } from "./cluster";
import * as cm from "@forgerock/pulumi-cert-manager"

// Get access to stack configuration values
const config = new Config();

// Define cert-manager values
const certManagerValues: cm.ChartArgs = {
    tlsKey: config.require("tls-key"),
    tlsCrt: config.require("tls-crt"),
    clusterProvider: cluster.provider,
    cloudDnsSa: config.require("clouddns"),
    dependency: cluster
}

// Deploy cert-manager
export const certManager = new cm.CertManager(certManagerValues);
