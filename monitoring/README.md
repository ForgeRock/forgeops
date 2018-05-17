# Prometheus and Grafana deployment

This deployment uses the [CoreOS Prometheus Operator](https://coreos.com/operators/prometheus/docs/0.15.0/index.html). 

**This Prometheus folder contains the following functions:**
* Prometheus Operator Helm chart.
* kube-prometheus Helm chart that contains child charts for:
    * GKE cluster monitoring,
    * Prometheus,
    * Grafana,
    * Alert Manager.
* exporter-forgerock Helm chart that include ServiceMonitors containing the endpoint details for ForgeRock products so Prometheus can  
scrape metrics.

<br />

# How Prometheus works

The Prometheus operator works by watching for ServiceMonitor CRDs (CRDs are Kubernetes Custom Resource Definitions). These are first  
class Kubernetes types that you can manage with kubectl (kubectl create/delete/patch, etc.).  The ServiceMonitor CRDs define the target to be scrapped.

The Prometheus operator watches for changes to current ServiceMonitors or for new ServiceMonitors and updates the  
Prometheus configuration with the details defined in the ServiceMonitors automatically.  

No restarting of Prometheus is required.

<br />

# How Grafana works

The Grafana Helm chart is deployed as part of the kube-prometheus chart.

* Grafana dashboard files are configured in the Grafana Helm chart as follows:
    * **grafana-dashboards.yaml** - GKE cluster monitoring dashboards.
    * **grafana-dashboards-am.yaml** - Forgerock AM dashboard.
    * **grafana-dashboards-ds.yaml** - Forgerock DS dashboard.
    * **grafana-dashboards-idm.yaml** - Forgerock IDM dashboard.
    * **grafana-dashboards-ig.yaml** - Forgerock IG dashboard.

These yaml files are defined as a Helm template object which is then included in a configmap (dashboards-configmap-yaml).  

The Grafana watcher picks up any new configuration and updates the dashboards automatically.  

No restarting of Grafana required.  

<br />

# Deployment Instructions
### Pre-requisites
* Deployed ForgeRock application in Google Cloud cluster.
* Kubectl authenticated to cluster.
* Separate namespace prepared for deploying Prometheus/Grafana
(Use namespace that is different to where your application is running).

### Prepare for deployment
* cd to root of forgeops-dashboard repo.

* Running the deployment without any overrides will use the default prometheus/helm/custom.yaml file which monitors default namespace and all ForgeRock  
 product endpoints.  If you wish to override these values follow the next steps, make copy of prometheus/helm/custom.yaml file amend  
 the following values:
    * add namespaces to be monitored in namespaceSelector array.  New line for each namespace.
    * enable/disable products that you wish to be monitored.

### Deploy

Run the deploy script ./bin/deploy_prometheus.sh with the following flags:
* -i (install) or -u (upgrade).
* -n *namespace* : to deploy Prometheus into.
* -f *values file* \[optional\] : absolute path to yaml file as defined in previous section.
* -h / no flags : view help

**NOTE**: if you change any of the Helm template files, upgrade the cluster by using the -u flag instead of -i (install).

### View Prometheus/Grafana

The following script uses kubectl port forwarding to access Prometheus and Grafana UIs. Run ./bin/connect.sh with the following flags:
* -G (Grafana) or -P (Prometheus).
* -n *namespace* : where Grafana/Prometheus is deployed.
* -p *port* \[optional\] : Grafana uses local port 3000 and Prometheus 9090. If you want to use different ports, or need to access  
multiple instance of Grafana/Prometheus, use the -p flag.
* -h / no flags : view help

View Prometheus:
* In browser: localhost:9090 (unless altered in the above script).
* Status/targets: to view whether targets are up or down and last scrape time.
* Status/configuration: to view the Prometheus scrape configs made up of all the configuration
provided by the Service Monitors

View Grafana:
* In browser: localhost:3000 (unless altered in the above script).
* Login for Grafana: admin/admin.
* View dashboards clicking top left icon then select dashboards.

<br />

# Configuration

### Configure new endpoints to be scraped by Prometheus

If you want Prometheus to scrape metrics from a different product, you need to create a new ServiceMonitor in the exporter-forgerock  
   Helm chart.  Please follow these steps:
* Copy the am.yaml ServiceMonitor file and rename file to \<product-name\>.yaml.
* Change the following fields:
    * change 'port: openam' to either port: \<port name\> or targetPort: \<port number\>
    * find and replace 'am' with 'product-name'.
    * If you don't require authentication to scrape the endpoint, then remove the basicAuth section.
* In values.yaml, copy the am section and create a new section as follows:
    ```
    <product name>:
        enabled: false      # overriden in custom.yaml
        path: /openam/json/metrics/prometheus       # metrics path
        labelSelectorComponent: openam      # kubernetes service label name
        secretUser: cHJvbWV0aGV1cw==        # username in base64 encode if required
        secretPassword: cHJvbWV0aGV1cw==        # password in base64 encode if required
    ```
* Update Prometheus with new ServiceMonitor
    ```
    ./bin/deploy_prometheus.sh -u -n <namespace> -f custom.yaml
    ```


### Configure new Grafana Dashboards

You will need to convert a exported Grafana json file into the correct format to work as a Kubernetes template object.
Some considerations:

* Ensure datasource is called prometheus.
* Ensure the root id is set to NULL.
    ```
        "id": null,
    ```
* Any grafana variables within the json file e.g. {{job}} must be formatted as {{\`{{job}}\`}}.
* An __inputs section within the json file is a prompt for user input e.g. datasource name. If this exists, an equivalent inputs  
 section must be provided.  For example:
    ```
        "__inputs": [
          {
            "name": "PROMETHEUS_DS",
            "label": "Prometheus DS",
            "description": "",
            "type": "datasource",
            "pluginId": "prometheus",
            "pluginName": "Prometheus"
          }
        ],
    ```
    must also be matched with a:

    ```
        "inputs": [
          {
            "name": "PROMETHEUS_DS",
            "pluginId": "prometheus",
            "type": "datasource",
            "value": "prometheus"
          }
        ],
    ```


To include a new Grafana dashboard, follow these steps:
* Create a new dashboard file grafana-dashboards-\<product-name\>.yaml in helm/grafana/.
* Create template replacing 'am' with your product name:
    ```
    {{ define "grafana-dashboards-am.yaml.tpl" }}
    am-dashboard.json: |
      {
        "dashboard":

       ###json file goes here

      }
    {{ end }}
    ```

*  Add the json file content where the comment is above.  You'll need to tab the whole json file so the open and close braces are  
 inline with the other open and close braces. See below:

    ```
        {{ define "grafana-dashboards-am.yaml.tpl" }}
        am-dashboard.json: |
          {
            "dashboard":
          {
            "id": null,
            "title": "ForgeRock Access Management Dashboard",
            "originalTitle": "ForgeRock Access Management Dashboard",

            ...

            "refresh": false,
            "schemaVersion": 12,
            "version": 2,
            "links": []
          }
          }
        {{ end }}
    ```

<br />

### Prometheus Operator configuration

The default Prometheus Operator configuration doesn't work in GKE without the following change in helm/exporter-kubelets/values.yaml:

```
https=false
```

Set to true for use within Minikube.












