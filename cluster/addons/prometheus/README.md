# Prometheus and Grafana deployment

The deployment uses the [Prometheus Operator](https://github.com/helm/charts/tree/master/stable/prometheus-operator). 

Alertmanager overview: [here](https://prometheus.io/docs/alerting/overview/).

Alertmanager configuration: [here](https://prometheus.io/docs/alerting/configuration/).

Grafana docs: [here](https://grafana.com/docs/grafana/latest/)

**Note**: Any scripts and folder locations mentioned below are relative to top level folder of forgeops. 

**Prometheus solution comprises of the following artifacts:**  

Helm charts:
* **prometheus-operator** deploys the Prometheus, Grafana and Alertmanager products along with the relevant metrics exporters. 
Creates custom resources which make the Prometheus deployment native to Kubernetes and configuration.
* **forgerock-metrics**  provides configurable ServiceMonitors, alerting rules and some custom ForgeRock dashboards.  ServiceMonitors define the ForgeRock Identity Platform  
component endpoints that are monitored by Prometheus.

Scripts:
* ```bin/prometheus-deploy.sh```: deploys the Helm charts mentioned above:
* ```bin/prometheus-connect.sh```: wrapper script for port-forwarding to Prometheus and Grafana endpoints.
  
Files:  

The ```bin/prometheus-deploy.sh``` uses files in cluster/addons/prometheus.
* ```prometheus-operator.yaml```: override values for Promethes Operator, Prometheus, Grafana and Alertmanager. The default values  
can be viewed [here](https://github.com/helm/charts/blob/master/stable/prometheus-operator/values.yaml).  Either update prometheus-operator.yaml  
or add your own override file with the -v flag 
    ```
    bin/deploy-prometheus.yaml -v <custom-values>.yaml
    ```
* ```forgerock-metrics```: Helm chart that includes ForgeRock service monitors, alerting rules and dashboards.

<br />

# How Prometheus Operator works

Prometheus Operator creates, configures, and manages Prometheus monitoring instances. The Prometheus Operator  
works by watching for ServiceMonitor CRDs (CRDs are Kubernetes Custom Resource Definitions). These are first  
class Kubernetes types that you can manage with kubectl (kubectl create/delete/patch, etc.).  The ServiceMonitor  
CRDs define the target to be scraped. 

Prometheus Operator also defines alerting rules CRDs which allow for easy deployment of alerting rule files.  

<br />

# How Prometheus works

The Prometheus scrape configuration is generated and updated automatically by the Prometheus Operater as described above.  
Prometheus uses its own config watcher to look for updated configurations.

<br />

# How Grafana works

The Grafana Helm chart is deployed as part of the prometheus-operator Helm chart.  Grafana automatically connects  
to Prometheus and syncs all the metrics which are visible through graphs.  

Dashboards for ForgeRock products are added to the cluster/addons/prometheus/forgerock-metrics/dashboards folder.  The dashboards are automatically added  
to a configmap and imported into Grafana.  For more info, see 'Import Custom Grafana Dashboards' in the 'How Tos'  
section below.

<br />

# How Alertmanager works
Alertmanager is used to redirect specific alerts from Prometheus to configured receivers.  
To configure Alertmanager, there is an Alertmanager configuration section in ```cluster/addons/prometheus/prometheus-operator.yaml```.  
Details about how to configure Alertmanager can be found in the link at the top of the page.  
In summary:
* global section defines attributes that apply to all alerts.
* route section defines a tree topology of alert filters to direct particular alerts to a specific receiver.  
Currently we're sending all alerts to a Slack receiver.
* receivers section defines named configurations of notification integrations.

Prometheus alerts are configured, by product, in the ```cluster/addons/prometheus/forgerock-metrics/fr-alerts.yaml``` file.  
A PrometheusRules CRD has been included in the Helm chart which includes the fr-alerts.yaml file and syncs the  
rules with Prometheus using labels.

# Deployment instructions
### Pre-requisites
* Deployed ForgeRock applications in Cloud Environment.
* Authenticated to cluster.

### Prepare for deployment
* cd to the bin folder in your forgeops repo clone.

* Running the deployment without any overrides will use the default values file which deploys to 'monitoring'  
namespace and scrapes metrics from all ForgeRock product endpoints, across all namespaces, based on configured labels.  

* To provide custom Prometheus, Alertmanager or Grafana configuration, see the  
**Overriding Prometheus and Alertmanager configuration values** 'How To' below.

### Deploy

Run the deploy script ```bin/prometheus-deploy.sh``` with the OPTIONAL flags:
* -n *namespace* \[optional\] : to deploy Prometheus into.  Default = monitoring.
* -v *custom values file* \[optional\] : absolute path to yaml file to override ```/path/to/<custom-values>.yaml```.
* -h view help

### View Prometheus/Grafana/Alertmanager

The following script uses kubectl port forwarding to access the Prometheus, Grafana and Alertmanager UIs.  
Run ```bin/prometheus-connect.sh``` with the following flags:  
* -G (Grafana), -P (Prometheus) or -A (Alertmanager).
* -n *namespace* \[optional\] : where Grafana/Prometheus/Alertmanager is deployed.  Default = monitoring.
* -p *port* \[optional\] : Grafana uses local port 3000, Prometheus 9090 and Alertmanager 9093. If you want to use different  
ports, or need to access multiple instance of Grafana/Prometheus/Alertmanager, use the -p flag.
* -h view help

View Prometheus:
* In browser: localhost:9090 (unless altered in the above script).
* Status/targets: to view whether targets are up or down and last scrape time.
* Status/configuration: to view the Prometheus scrape configs made up of all the configuration
provided by the Service Monitors

View Grafana:
* In browser: localhost:3000 (unless altered in the above script).
* Login for Grafana: admin/admin.
* View dashboards clicking top left icon then select dashboards.

View Alertmanager:
* In browser: localhost:9093 (unless altered in the above script).
* Status: view Alertmanager configuration.
* Alerts: current alerts.

<br />

# How Tos.

### Configure new endpoints to be scraped by Prometheus.

If you want Prometheus to scrape metrics from a different product, you need to create a new ServiceMonitor in the  
exporter-forgerock Helm chart.  Please follow these steps:
* Copy the am.yaml ServiceMonitor file and rename file to \<product-name\>.yaml.
* Change the following fields:
    * change 'port: am' to either port: \<port name\> or targetPort: \<port number\>
    * find and replace 'am' with 'product-name'.
    * If you don't require authentication to scrape the endpoint, then remove the basicAuth section.
* In values.yaml, copy the below am section and create a new section as described by the comments:
    ```
    <product name>:
        component: am   # product name to define the ServiceMonitor
        enabled: false      # overriden in custom.yaml
        path: /json/metrics/prometheus       # metrics path
        labelSelectorComponent: am      # kubernetes service label name
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
    bin/prometheus-deploy.sh [-n <namespace>]
    ```

### Overriding Prometheus, Alertmanager and Grafana configuration values.
The default deployment uses configuration values in ```cluster/addons/prometheus/prometheus-operator.yaml```. This file is just  
an override of the prometheus-operator Helm chart default values file.  This file contains configuration values for Prometheus,  
Alertmanager and Grafana.

You can provide your own custom configuration by customizing a copy of ```prometheus-operator.yaml``` and deploying as follows:
```
    bin/prometheus-deploy.sh -v <path/to/custom-prometheus-operator.yaml>
```

The main uses of this custom file will be to:
* customize the Alertmanager configuration which determines whether to send alert notifications to a particular receiver  
(Slack for example).
* customize the Prometheus configuration to include new endpoints to monitor as described in the  
**Configure new endpoints to be scraped by Prometheus** 'How To' (e.g. an additional service that's running alongside  
FR products). 
* customize the Grafana configuration.  

All values can be found in the Prometheus Operator Helm chart values file [here](https://github.com/helm/charts/blob/master/stable/prometheus-operator/values.yaml).
 

### Configure alerting rules.
To add new alerting rules, add additional rules to ```fr-alerts.yaml```. fr-alerts.yaml is split into groups with a  
group for each product and a separate group for cluster rules.  

See [Prometheus alerting](https://prometheus.io/docs/practices/alerting/) for details on configuring alerts.   

### Configure alert notifications.
The default Alertmanager configuration in ```cluster/addons/prometheus/prometheus-operator.yaml``` is not configured to send any alert  
notifications. See the alertmanager.config section in the Prometheus Operator Helm  chart values file.

See [Alertmanager configuration](https://prometheus.io/docs/alerting/configuration/) and [Alertmanger notifications](https://prometheus.io/docs/alerting/notifications/) for more details.

### Import Custom Grafana Dashboards.
Grafana comes with a set of predefined Grafana dashboards for viewing Kubernetes and cluster metrics.  Further custom  
dashboards can be added to the deployment by adding the dasboard json files into the ```cluster/addons/prometheus/forgerock-metrics/dashboards``` folder. 

### Expose Prometheus and Grafana externally.
External access is enabled by default using host ```<prometheus|grafana|alertmanager>.iam.example.com```.  
To change the hostname, just edit the <prometheus|grafana|alertmanager>.ingress.hosts value in ```prometheus-operator.yaml```.


The labels are optional and the hostname and secret name align with the current deployment of forgeops with cert-manager.














