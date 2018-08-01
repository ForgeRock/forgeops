# Prometheus and Grafana deployment

The deployment uses the [CoreOS Prometheus Operator](https://coreos.com/operators/prometheus/docs/0.15.0/index.html). 

Alertmanager overview: [Overview](https://prometheus.io/docs/alerting/overview/).

Alertmanager configuration: [Config](https://prometheus.io/docs/alerting/configuration/).


**Prometheus solution comprises of the following artifacts:**  

Helm charts:
* ***prometheus-operator*** which creates custom resources which makes the Prometheus deployment native to Kubernetes and configuration through Kubernetes manifests.
* ***kube-prometheus*** which contains multiple subcharts including Prometheus, Grafana and Alertmanager and other Helm charts that monitor GKE.
* ***forgerock-metrics***  provides configurable ServiceMonitors, alerting rules and a job to automatically import Grafana dashboards for ForgeRock products.  ServiceMonitors define the ForgeRock Identity Platform component endpoints that are monitored by Prometheus.

Scripts:
* **bin/deploy_prometheus.sh**: deploys the Helm charts mentioned above:
* **bin/remove_prometheus.sh**: remove all deployed Helm charts described above.
* **bin/connect_prometheus.sh**: wrapper script for port-forwarding to Prometheus and Grafana endpoints.
  
Values files:
* ***etc/prometheus_values/kube_prometheus.yaml***: override values for kube-prometheus Helm chart. Here you can configure Prometheus and Alertmanager as well as define which Kubernetes you would like monitored.
* ***etc/prometheus_values/prometheus_operator.yaml***: override values for Prometheus Operator.  Main use so far is to configure the image version.
  
Grafana auto import.
* ***docker/auto-import*** folder which provides a Dockerfile for producing the docker image used by the import-dashboards job.

<br />

# How Prometheus works

The Prometheus Operator works by watching for ServiceMonitor CRDs (CRDs are Kubernetes Custom Resource Definitions). These are first  
class Kubernetes types that you can manage with kubectl (kubectl create/delete/patch, etc.).  The ServiceMonitor CRDs define the target to be scraped.

The Prometheus Operator watches for changes to current or new ServiceMonitors and updates the Prometheus configuration with the details  
defined in the ServiceMonitors automatically.  

No restarting of Prometheus is required.

<br />

# How Grafana works

The Grafana Helm chart is deployed as part of the kube-prometheus chart.  Grafana automatically connects to Prometheus and syncs all  
the metrics which are visible through Graphs.  

Dashboards for ForgeRock products are imported into Grafana post-deployment. A Kubernetes job mounts the dashboard files from the helm/forgerock-metrics/dashboards  
folder, formats them to bypass a couple of limitations in the Grafana import API, and then uses the API to import them.

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
(Use a namespace that is different to where your application is running. The default is 'monitoring').

### Prepare for deployment
* cd to the bin folder in your forgeops repo clone.

* Running the deployment without any overrides will use the default values file which deploys to 'monitoring' namespace and scrapes metrics  
 from all ForgeRock product endpoints, across all namespaces, based on configured labels.  
 If you wish to override these values, create a new custom.yaml file, add your override configuration using helm/forgerock-metrics/values.yaml  
 as a guide, and run deploy_prometheus.sh -f \<custom yaml file\>.

### Deploy

Run the deploy script ./deploy_prometheus.sh with the OPTIONAL flags:
* -n *namespace* \[optional\] : to deploy Prometheus into.  Default = monitoring.
* -f *values file* \[optional\] : absolute path to yaml file as defined in previous section.
* -h / no flags : view help

### View Prometheus/Grafana

The following script uses kubectl port forwarding to access the Prometheus and Grafana UIs. Run ./connect_prometheus.sh with the following flags:
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

# How Tos

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
    ./deploy_prometheus.sh [-n <namespace>]
    ```

### Configure alerting rules
To add new alerting rules, add additional rules to fr-alerts.yaml. fr-alerts.yaml is split into groups with a group for each product and a  
separate group for cluster rules.  

See [Prometheus alerting](https://prometheus.io/docs/practices/alerting/) for details on configuring alerts. 

### Configure the alert message output(Slack).
The alert output can be configured in the Alertmanager section of the kube-prometheus.yaml. In the slack_configs section of the receiver block,  
you can define the template for the alert output.  The output text also incorporates labels so the info can be dynamically imported from the original  
alert definition(see the Configuring alerting rules how to).  

See [Alertmanager configuration](https://prometheus.io/docs/alerting/configuration/) and [Alertmanger notifications](https://prometheus.io/docs/alerting/notifications/) for more details.


### Import Custom Grafana Dashboards

The easiest way to import dashboards is to manually import the JSON files in the GUI.  
Currently exporting then importing dashboards via the HTTP API doesn't work correctly and requires manual amendments.

### Add new dashboards to the auto import job
To add further custom Grafana dashboards as part of the deployment, a new method of importing dashboards will be developed shortly  
to avoid the the limitations currently in the Grafana import API. Until now use the manual import option.













