import * as pulumi from "@pulumi/pulumi";
import * as k8s from "@pulumi/kubernetes";

import { ConfigFile, ConfigGroup } from "@pulumi/kubernetes/yaml";
import { Config, ResourceOptions } from "@pulumi/pulumi";
import { clusterProvider } from "./cluster";
import { nginx } from "./nginx-controller"

const config = new Config();

// Deploy cert-manager
const certmanagerResources = new ConfigFile("cmResources", {
    file: "https://github.com/jetstack/cert-manager/releases/download/v0.8.1/cert-manager.yaml", 
},{ dependsOn: [nginx], provider: clusterProvider });

// Deploy secret - certificate for cert-manager ca certificate(self signed)
const caSecret = new k8s.core.v1.Secret("certmanager-ca-secret",{
    metadata: {
        name: "certmanager-ca-secret", 
        namespace: "cert-manager",
    },
    type: "kubernetes.io/tls",
    stringData: {
        "tls.key": config.require("tls-key"),
        "tls.crt": config.require("tls-crt"),
    }
},{ dependsOn: [certmanagerResources], provider: clusterProvider });

// Deploy secret - service account for access to Cloud DNS
const clouddns = new k8s.core.v1.Secret("clouddns",{
    metadata: {
        name: "clouddns",
        namespace: "cert-manager"
    },
    type: "Opaque",
    stringData: {
        "cert-manager.json": config.require("clouddns")
    }
},{ dependsOn: [certmanagerResources], provider: clusterProvider });

 // Deploy cert-manager issuers
export const certmanager = new ConfigGroup("certManager", {
    files: [
        'files/cert-manager/ca-issuer.yaml',
        'files/cert-manager/le-issuer.yaml'
    ]
},{ dependsOn: [certmanagerResources,caSecret,clouddns], provider: clusterProvider });





