import { Config } from "@pulumi/pulumi";
import { clusterProvider, primaryPool } from "./cluster";
import * as cm from "@forgerock/pulumi-cert-manager"

const config = new Config();

const certManagerValues: cm.ChartArgs = {
    tlsKey: config.require("tls-key"),
    tlsCrt: config.require("tls-crt"),
    clusterProvider: clusterProvider,
    cloudDnsSa: config.require("clouddns")
}

//export const certManager = new cm.CertManager("cert-manager", certManagerValues, {dependsOn: [primaryPool], provider: clusterProvider});





