import { Config } from "@pulumi/pulumi";
import * as cluster from "./cluster";
import * as cm from "../packages/cert-manager"

// Get access to stack configuration values
const config = new Config();

export let certManager:cm.CertManager;

// Define cert-manager values
const certManagerValues: cm.ChartArgs = {
    tlsKey: config.require("tls-key"),
    tlsCrt: config.require("tls-crt"),
    clusterProvider: cluster.clusterProvider,
    cloudDnsSa: config.require("clouddns"),
    dependency: cluster.primaryPool
}


let enableCertManager = config.getBoolean("enableCertManager") || false;

if( enableCertManager) {
    certManager = new cm.CertManager(certManagerValues);
}