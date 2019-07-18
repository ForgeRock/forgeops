## Deploy Nginx Ingress Controller with Pulumi for ForgeRock cloud deployments 

Import package:
```
import * as ingressController from "@forgerock/pulumi-nginx-ingress-controller";
```

Create namespace:
```
const nsnginx = new k8s.core.v1.Namespace("nginx", { 
    metadata: { 
        name: "nginx" 
    }
}, { provider: clusterProvider });
```

Configure required arguments for Nginx Helm chart:

```
const nginxValues: ingressController.ChartArgs = {
    ip: "35.10.10.200",                // static IP address
    version: "0.24.1",                 // Ingress controller version  
    clusterProvider: clusterProvider,  // Your cluster provider
    namespace: nsnginx.metadata.name   // namespace 
}
```

Deploy Nginx Ingress Controller:
```
const nginxControllerChart = new ingressController.NginxIngressController(nginxValues);
```
