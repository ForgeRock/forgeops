# Prometheus and Grafana deployment

The deployment uses the [CoreOS Prometheus Operator](https://coreos.com/operators/prometheus/docs/0.15.0/index.html). 

Alertmanager overview: [here](https://prometheus.io/docs/alerting/overview/).

Alertmanager configuration: [here](https://prometheus.io/docs/alerting/configuration/).


**Prometheus solution comprises of the following artifacts:**  

Helm charts:
* ***prometheus-operator*** creates custom resources which makes the Prometheus deployment native to  
Kubernetes and configuration through Kubernetes manifests.
* ***kube-prometheus*** contains multiple subcharts including Prometheus, Grafana and Alertmanager and  
other Helm charts that monitor GKE.
* ***forgerock-metrics***  provides configurable ServiceMonitors, alerting rules and a job to automatically  
import Grafana dashboards for ForgeRock products.  ServiceMonitors define the ForgeRock Identity Platform  
component endpoints that are monitored by Prometheus.

Scripts:
* **bin/deploy-prometheus.sh**: deploys the Helm charts mentioned above:
* **bin/remove-prometheus.sh**: removes all deployed Helm charts described above.
* **bin/connect-prometheus.sh**: wrapper script for port-forwarding to Prometheus and Grafana endpoints.
* **bin/format-grafana-dashboards.sh**: script to format Grafana dashboards to be included in the deployment.
  
Values files:
* ***etc/prometheus-values/prometheus-operator.yaml***: override values for Prometheus Operator. 
* ***etc/prometheus-values/kube-prometheus.yaml***: override values for kube-prometheus Helm chart. Here you  
can configure Prometheus, Alertmanager and Grafana as well as define which Kubernetes you would like monitored.  
These values are the default values used in ```bin/deploy-prometheus.yaml```.
* ***samples/config/prometheus-values/\<custom-values\>.yaml***: additional values used to define cluster  
specific configuration.  Use ```bin/deploy-prometheus.yaml -k <custom-values>.yaml```.

<br />

# How Prometheus Operator works

Prometheus Operator creates, configures, and manages Prometheus monitoring instances. The Prometheus Operator  
works by watching for ServiceMonitor CRDs (CRDs are Kubernetes Custom Resource Definitions). These are first  
class Kubernetes types that you can manage with kubectl (kubectl create/delete/patch, etc.).  The ServiceMonitor  
CRDs define the target to be scraped. 

Prometheus Operator also defines alerting rules CRDs which allow for easy deployment of alerting rule files.  

<br />

# How Prometheus works

The Prometheus Helm chart is deployed as part of the kube-prometheus Helm chart.  The Prometheus scrape  
configuration is generated and updated automatically by the Prometheus Operater as described above.  Prometheus  
uses its own config watcher to look for updated configurations.

<br />

# How Grafana works

The Grafana Helm chart is deployed as part of the kube-prometheus Helm chart.  Grafana automatically connects  
to Prometheus and syncs all the metrics which are visible through graphs.  

Dashboards for ForgeRock products are added to the helm/forgerock-metrics/dashboards folder.  Any new dashboards  
must be formatted using the script ```bin/format-grafana-dashboards.sh```.  The dashboards are automatically added  
to a configmap and imported into Grafana.  For more info, see 'Import Custom Grafana Dashboards' in the 'How Tos'  
section below.

<br />

# How Alertmanager works
Alertmanager is used to redirect specific alerts from Prometheus to configured receivers.  
To configure Alertmanager, there is an Alertmanager configuration section in ```etc/prometheus-values/kube-prometheus.yaml```.  
Details about how to configure Alertmanager can be found in the link at the top of the page.  
In summary:
* global section defines attributes that apply to all alerts.
* route section defines a tree topology of alert filters to direct particular alerts to a specific receiver.  
Currently we're sending all alerts to a Slack receiver.
* receivers section defines named configurations of notification integrations.

Prometheus alerts are configured, by product, in the ```helm/forgerock-metrics/fr-alerts.yaml``` file.  
A PrometheusRules CRD has been included in the Helm chart which includes the fr-alerts.yaml file and syncs the  
rules with Prometheus using labels.

# Deployment instructions
### Pre-requisites
* Deployed ForgeRock application in Google Cloud cluster.
* Authenticated to cluster.

### Prepare for deployment
* cd to the bin folder in your forgeops repo clone.

* Running the deployment without any overrides will use the default values file which deploys to 'monitoring'  
namespace and scrapes metrics from all ForgeRock product endpoints, across all namespaces, based on configured labels.  

* To override these values, create a new custom.yaml file, add your override configuration using  
```helm/forgerock-metrics/values.yaml```  as a guide, and run ```deploy-prometheus.sh -f \<custom yaml file\>```.

* To provide custom Prometheus, Alertmanager or Grafana configuration, see the  
**Overriding Prometheus and Alertmanager configuration values** 'How To' below.

### Deploy

Run the deploy script ```./deploy-prometheus.sh``` with the OPTIONAL flags:
* -n *namespace* \[optional\] : to deploy Prometheus into.  Default = monitoring.
* -f *values file* \[optional\] : absolute path to yaml file to override ```helm/forgerock-metrics/values.yaml```.
* -k *values file* \[optional\] : absolute path to yaml file to override ```etc/prometheus-values/kube-prometheus.yaml```.
* -h / no flags : view help

### View Prometheus/Grafana/Alertmanager

The following script uses kubectl port forwarding to access the Prometheus and Grafana UIs.  
Run ```./connect-prometheus.sh``` with the following flags:  
* -G (Grafana) or -P (Prometheus).
* -n *namespace* \[optional\] : where Grafana/Prometheus/Alertmanager is deployed.  Default = monitoring.
* -p *port* \[optional\] : Grafana uses local port 3000, Prometheus 9090 and Alertmanager 9093. If you want to use different  
ports, or need to access multiple instance of Grafana/Prometheus/Alertmanager, use the -p flag.
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
    * change 'port: openam' to either port: \<port name\> or targetPort: \<port number\>
    * find and replace 'am' with 'product-name'.
    * If you don't require authentication to scrape the endpoint, then remove the basicAuth section.
* In values.yaml, copy the below am section and create a new section as described by the comments:
    ```
    <product name>:
        component: am   # product name to define the ServiceMonitor
        enabled: false      # overriden in custom.yaml
        path: /json/metrics/prometheus       # metrics path
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
* Include the new ServiceMonitor name in ```/etc/prometheus-values/kube-prometheus.yaml``` under the  
prometheus/serviceMonitorsSelector section.  If this a temporary addition deploy it as an override as described in the  
**Overriding Prometheus and Alertmanager configuration values** 'How To'.
* Update Prometheus with new ServiceMonitor
    ```
    ./deploy-prometheus.sh [-n <namespace>]
    ```

### Overriding Prometheus, Alertmanager and Grafana configuration values.
The default deployment uses configuration values in ```etc/prometheus-values/kube-prometheus.yaml```. This file is just  
a copy of the kube-prometheus Helm chart values file.  This file contains configuration values for Prometheus and  
Alertmanager and flags to toggle different metric gathering services(exporters).  You can also override Grafana values  
by adding a Grafana section to your override file as discussed below.

You can provide your own custom configuration by customizing a copy of ```kube-prometheus.yaml``` and deploying as follows:
```
    ./deploy-prometheus.sh -k <path to custom kube-prometheus.yaml file>
```

The main uses of this custom file will be to:
* customize the Alertmanager configuration which determines whether to send alert notifications to a particular receiver  
(Slack for example).
* customize the Prometheus configuration to include new endpoints to monitor as described in the  
**Configure new endpoints to be scraped by Prometheus** 'How To' (e.g. an additional service that's running alongside  
FR products). 
* customize the Grafana configuration.  

Documentation links are embedded in the values files for guidance.  
Sample configuration files can be found in the samples/prometheus-values/ folder.  

### Configure alerting rules.
To add new alerting rules, add additional rules to ```fr-alerts.yaml```. fr-alerts.yaml is split into groups with a  
group for each product and a separate group for cluster rules.  

See [Prometheus alerting](https://prometheus.io/docs/practices/alerting/) for details on configuring alerts.   

### Configure alert notifications.
The default Alertmanager configuration in ```etc/prometheus-values/kube-prometheus.yaml``` is not configured to send any alert  
notifications. This can be customized by following the steps in the previous 'How To' **Overriding Prometheus, Alertmanager and  
Grafana configuration values.** and configuring the sections described below.  

* Alert grouping and filtering can be configured in the alertmanager.config.route section
* Notifications are configured in the alertmanager.config.receivers section where you can also define a template for the alert  
output text.  The output text also incorporates labels so the info can be dynamically imported from the original alert definition  
(see the **Configuring alerting rules** 'How To').  

See [Alertmanager configuration](https://prometheus.io/docs/alerting/configuration/) and [Alertmanger notifications](https://prometheus.io/docs/alerting/notifications/) for more details.

### Import Custom Grafana Dashboards.
Grafana comes with a set of predefined Grafana dashboards for viewing Kubernetes and cluster metrics.  Further custom  
dashboards can be added to the deployment but required some specific formatting so they can be recognised by the Grafana  
watcher and imported into Grafana.  

There is a script called ```bin/format-grafana-dashboards.sh``` which takes care of the formatting.  Please read the notes  
in the script prior to running.  Just ensure you edit the $BASH_DIR variable that stores the location of the new dashboards  
so its in a different location to the formatted dashboards($PROCESSED_DIR).  Please don't change $PROCESSED_DIR.  

**```NOTE:```** This script only needs to be ran once.

### Expose Prometheus and Grafana externally.
To expose monitoring endpoints externally, add the following ingress section under Prometheus, Grafana and Alertmanager values sections in you override configuration as described in an earlier 'How To'. Here's an example for the Grafana section:

```
grafana:
  ingress:
    enabled: true

    annotations: 
      kubernetes.io/ingress.class: nginx
      kubernetes.io/tls-acme: "true"

    labels:
      group: monitoring-ingress
      product: grafana
      
    hosts:
      - grafana.monitoring.example.com
      
    tls:
      - secretName: wildcard.monitoring.example.com
        hosts:
          - grafana.monitoring.example.com
```

The labels are optional and the hostname and secret name align with the current deployment of forgeops with cert-manager.














