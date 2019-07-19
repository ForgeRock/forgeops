## Deploy cert-manager with Pulumi for ForgeRock cloud deployments 

Import package:
```
import * as certManager from "@forgerock/pulumi-cert-manager";
```

Get access to stack configuration values
```
const config = new Config();
```

Set cert-manager configuration values.
```
const certManagerValues: cm.ChartArgs = {
    tlsKey: config.require("tls-key"),      // TLS key for CA cert.
    tlsCrt: config.require("tls-crt"),      // TLS cert for CA cert.
    clusterProvider: clusterProvider,       // Your cluster provider.
    cloudDnsSa: config.require("clouddns"), // Cloud DNS service account.
    nodePoolDependency: primaryPool         // Node Pool to use for resource dependency. 
}
```

Deploy cert-manager
```
export const certManager = new cm.CertManager(certManagerValues);
```