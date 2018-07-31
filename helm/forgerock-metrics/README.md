# Prometheus and Grafana deployment

The deployment uses the [CoreOS Prometheus Operator](https://coreos.com/operators/prometheus/docs/0.15.0/index.html). 

Alertmanager overview: [Overview](https://prometheus.io/docs/alerting/overview/).

Alertmanager configuration: [Config](https://prometheus.io/docs/alerting/configuration/).

**Note**: All mentioned scripts are available in the bin/ directory.

**The monitoring folder contains the following artifacts:**
* deploy scripts to:
    * deploy the Prometheus Operator along with Grafana and Alert Manager and other Helm charts that help monitor GKE.
    * connect to the Prometheus and Grafana endpoints.
* forgerock-metrics Helm chart that provides configurable ServiceMonitors and a job to automatically import Grafana dashboards for ForgeRock products.  ServiceMonitors define the ForgeRock Identity Platform component endpoints that are monitored by Prometheus.
* values files that are used by the deploy script and can be edited to customize the configuration of Prometheus, Grafana and Alert Manager.
* auto-import folder which provides a Dockerfile for producing the docker image used by the import-dashboards job.

<br />

# How Prometheus works

The Prometheus Operator works by watching for ServiceMonitor CRDs (CRDs are Kubernetes Custom Resource Definitions). These are first  
class Kubernetes types that you can manage with kubectl (kubectl create/delete/patch, etc.).  The ServiceMonitor CRDs define the target to be scraped.

The Prometheus Operator watches for changes to current ServiceMonitors or for new ServiceMonitors and updates the  
Prometheus configuration with the details defined in the ServiceMonitors automatically.  

No restarting of Prometheus is required.

<br />

# How Grafana works

The Grafana Helm chart is deployed as part of the kube-prometheus chart.  This comes prepackaged with ServiceMonitors and  
dashboards that monitor various aspects of the GKE cluster including the cluster node resources and Kubernetes objects.

Dashboards for ForgeRock products are imported into Grafana after Grafana has been deployed. 

<br />

# How Alertmanager works
Alertmanager is used to redirect specific alerts from Prometheus to configured receivers.  
To configure Alertmanager, there is an Alertmanager configuration section in etc/prometheus_values/kube-prometheus.yaml.  
Details about how Alertmanager works can be found in the link at the top of the page.  
In summary:
* global section defines attributes that apply to all alerts.
* route section defines a tree topology of alert filters to direct particular alerts to a specific receiver.  
Currently we're sending all alerts to a Slack receiver.
* receivers section defines named configurations of notification integrations.

Prometheus alerts are configured, by product, in the helm/forgerock-metrics/fr-alerts.yaml file.  
A PrometheusRules CRD has been included in the Helm chart which includes the fr-alerts.yaml file and syncs the rules with Prometheus using labels.

# Deployment instructions
### Pre-requisites
* Deployed ForgeRock application in Google Cloud cluster.
* Kubectl authenticated to cluster.
* Separate namespace prepared for deploying Prometheus/Grafana
(Use namespace that is different to where your application is running).

### Prepare for deployment
* cd to monitoring folder within forgeops repo.

* Running the deployment without any overrides will use the default values file which deploys to 'monitoring' namespace and scrapes metrics  
 from all ForgeRock product endpoints, across all namespaces, based on configured labels.  
 If you wish to override these values, create a new custom.yaml file, add your override configuration using helm/forgerock-metrics/values.yaml  
 as a guide, and run prom_deploy.sh -f \<custom yaml file\>.

### Deploy

Run the deploy script ./prom_deploy.sh with the OPTIONAL flags:
* -n *namespace* \[optional\] : to deploy Prometheus into.  Default = monitoring.
* -f *values file* \[optional\] : absolute path to yaml file as defined in previous section.
* -h / no flags : view help

### View Prometheus/Grafana

The following script uses kubectl port forwarding to access Prometheus and Grafana UIs. Run ./bin/prom_connect.sh with the following flags:
* -G (Grafana) or -P (Prometheus).
* -n *namespace* \[optional\] : where Grafana/Prometheus is deployed.  Default = monitoring.
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
* In values.yaml, copy the below am section and create a new section as described by the comments:
    ```
    <product name>:
        component: am   # product name to define the ServiceMonitor
        enabled: false      # overriden in custom.yaml
        path: /openam/json/metrics/prometheus       # metrics path
        labelSelectorComponent: openam      # kubernetes service label name
        secretUser: cHJvbWV0aGV1cw==        # username in base64 encode if required
        secretPassword: cHJvbWV0aGV1cw==        # password in base64 encode if required
    ```
* The default scope for Prometheus is to scrape all namespaces configured in values.yaml like this:
    ```
    namespaceSelectorStrategy: any
    ```
  If you want to limit this scope, you can define a list of namespace, for example:
    ```
    namespaceSelectorStrategy: selection
    namespaceSelector:
      - production
      - staging
      - test
    ```
* Update Prometheus with new ServiceMonitor
    ```
    ./prom_deploy.sh [-n <namespace>]
    ```


### Import Custom Grafana Dashboards

The easiest way to import dashboards, is to manually import the json files in the GUI.
Currently exporting then importing dashboards via the HTTP api doesn't work correctly and requires manual amendments.












