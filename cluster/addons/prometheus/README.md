# Prometheus and Grafana deployment

The CDM uses the
[kube-prometheus-stack Helm chart](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
for monitoring and alerts. Before you attempt to customize the default
implementation, make sure you are familiar with Prometheus, Alertmanager, and
Grafana concepts in the following documentation:

* [Alertmanager overview](https://prometheus.io/docs/alerting/overview/)

* [Alertmanager configuration](https://prometheus.io/docs/alerting/configuration/)

* [Grafana](https://grafana.com/docs/grafana/latest/)

The following sections list the forgeops repository artifacts that are used to
deploy Prometheus,Alertmanager, and Grafana in the CDM.  

## Helm charts

* The ``kube-prometheus-stack`` chart deploys Prometheus, Alertmanager, and 
Grafana software. It also deploys the relevant metrics exporters. The
deployment creates custom resources to make Prometheus native to Kubernetes.
  
* The ``forgerock-metrics`` chart provides configurable service monitors,
alerting rules and custom ForgeRock dashboards. Service monitors define the
ForgeRock Identity Platform component endpoints that Prometheus monitors.

## Scripts

* The ``bin/prometheus-deploy.sh`` script deploys the Helm charts mentioned
above.
  
* The ``bin/prometheus-connect.sh`` wrapper script port forwards the
Prometheus, Alertmanager, and Grafana endpoints.
  
Note: All path locations mentioned in this README are relative to the forgeops
repository's top-level directory.
  
## Files in the ``cluster/addons/prometheus`` directory  

* ``prometheus-operator.yaml``: Overrides values for the Prometheus operator,
Prometheus, Alertmanager, and Grafana. See the `prometheus-community/kube-prometheus-stack`
[values file](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
for default values. To modify default values, override the
``prometheus-operator.yaml`` file, or specify your own values file when you deploy Prometheus. For example:
  
```bash
    bin/deploy-prometheus.yaml -v <custom-values>.yaml
```

* ``forgerock-metrics``: a Helm chart that contains ForgeRock service
monitors, alerting rules, and dashboards.

<br />

## How the Prometheus operator works

The Prometheus operator creates, configures, and manages Prometheus monitoring
instances. The operator works by watching for service monitor CRDs. These CRDs
are first-class Kubernetes types that you can manage with the ``kubectl``
command.  The service monitor CRDs define targets to be scraped.

The operator also defines alerting rules CRDs that allow for easy deployment of
alerting rule files.  

<br />

## How Prometheus works

The Prometheus scrape configuration is generated and updated automatically by
the Prometheus operator, as described above. Prometheus uses its own
configuration watcher to look for updated configurations.

<br />
## How Alertmanager works

Alertmanager is used to redirect specific alerts from Prometheus to configured
receivers. Use the Alertmanager configuration section in
the ``cluster/addons/prometheus/prometheus-operator.yaml`` directory to
configure Alertmanager.  

Alertmanager configuration details:

* The ``global`` section defines attributes that apply to all alerts.
  
* The ``route`` section defines a tree topology of alert filters to direct
particular alerts to a specific receiver. The example deployment sends all
alerts to a Slack receiver.
  
* The ``receivers`` section defines named configurations of notification
integrations.

Prometheus alerts are configured by product, in the
``cluster/addons/prometheus/forgerock-metrics/fr-alerts.yaml`` file.  
The Helm chart that includes the ``fr-alerts.yaml`` file also contains
a Prometheus rules CRD. The CRD syncs the rules with Prometheus using labels.

<br />

## How Grafana works

The Grafana Helm chart is deployed as part of the ``kube-prometheus-stack`` Helm
chart.  Grafana automatically connects to Prometheus and syncs all the metrics.
The metrics are visible through graphs.  

Dashboards for ForgeRock products are added to the Grafana deployment from the
``cluster/addons/prometheus/forgerock-metrics/dashboards`` directory.  The
dashboards are automatically added to a configmap, and then imported into
Grafana. For more information, see the **Import Custom Grafana Dashboards** how-to below.

<br />

## Deployment instructions

### Prerequisites

* The ForgeRock applications are deployed in a cloud environment.
* You have authenticated to a Kubernetes cluster.

### To Deploy

* ``cd`` to the ``bin`` folder in your forgeops repository clone.

* Run the ``prometheus-deploy.sh`` script:

  * Running the deployment without any overrides uses the default values file,
which deploys to the ``monitoring`` namespace, and scrapes metrics from all
ForgeRock product endpoints, across all namespaces, based on configured labels.  

  * If you want to provide custom Prometheus, Alertmanager or Grafana
configuration values, see the  
**Override Prometheus and Alertmanager configuration values** how-to below.

### Start the Prometheus, Alertmanager, and Grafana UIs

Before attempting to access the Prometheus, Grafana, and Alertmanager UIs,
forward ports using the ```bin/prometheus-connect.sh``` script:

* For Grafana, run ``bin/prometheus-connect.sh -G``

* For Alertmanager, run ``bin/prometheus-connect.sh -A``

* For Prometheus, run ``bin/prometheus-connect.sh -P``

By default, Grafana uses local port 3000, Prometheus, port 9090 and
Alertmanager, 9093. You can specify alternate ports using the ``-p`` option
when you run the ``prometheus-connect.sh`` script.

To access the UIs on the default ports:

* For Grafana, go to localhost:3000. User admin/admin to log in. To view
dashboards, select the top left icon, then select Dashboards.

* For Alertmanager, go to localhost:9093. Select Status to see the Alertmanager
configuration. Select Alerts to see current Alerts.
  
* For Prometheus, go to localhost:9090. Select Status > Targets to see whether
targets are up or down and the last scrape time. Select Status > Configuration
to see the Prometheus scrape configurations provided by the service monitors.
 
<br />

## How-tos

### Configure new endpoints to be scraped by Prometheus

If you want Prometheus to scrape metrics from a different product, you need to
create a new service monitor in the ``exporter-forgerock`` Helm chart.  Follow
these steps:

* Copy the ``am.yaml`` service monitor file and rename the new file to
``\<product-name\>.yaml``.
  
* Change the following fields:
  
  * Change ``port: am`` to either ``port: \<port name\>`` or
``targetPort: \<port number\>``.

  * Find and replace ``am`` with ``product-name``.

  * If you don't require authentication to scrape the endpoint, then remove the
``basicAuth`` section.

  * In the ``values.yaml`` file, create a new section based on the ``am`` section.
Change the values in the new section as described by the comments:

    ```yaml
    <product name>:
        component: am   # product name to define the ServiceMonitor
        enabled: false      # overriden in custom.yaml
        path: /json/metrics/prometheus       # metrics path
        labelSelectorComponent: am      # kubernetes service label name
        secretUser: cHJvbWV0aGV1cw==        # username in base64 encode if required
        secretPassword: cHJvbWV0aGV1cw==        # password in base64 encode if required
    ```
  
  * The default scope for Prometheus is to scrape all namespaces configured in
the ``values.yaml`` file, like this:

    ```yaml
    namespaceSelectorStrategy: any
    ```

  * If you want to limit this scope, you can define a list of namespaces. For
example:

    ```yaml
    namespaceSelectorStrategy: selection
    namespaceSelector:
      - production
      - staging
      - test
    ```

  * Update Prometheus with the new service monitor:

    ```bash
    bin/prometheus-deploy.sh [-n <namespace>]
    ```

### Override Prometheus, Alertmanager and Grafana configuration values

The entire configuration for Prometheus, Alertmanager, and Grafana can be found
in the `kube-prometheus-stack`
[values file](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack).
Configuration overrides for the CDM are contained in the
``cluster/addons/prometheus/prometheus-operator.yaml`` file. If you want to
specify additional customized configuration values, do one of the following:

* Extend the ``cluster/addons/prometheus/prometheus-operator.yaml`` file, adding
your custom configuration values to the file.

* Provide your own custom configuration by copying the
``prometheus-operator.yaml`` file and modifying it with your custom
configuration values. Then, specify the customized configuration file when you
deploy the Prometheus operator:

```bash
    bin/prometheus-deploy.sh -v /path/to/custom-prometheus-operator.yaml
```

### Configure alerting rules

To add new alerting rules, add rules to the ``fr-alerts.yaml`` file. This file
is split into groups, with a group for each product, and a separate group for
cluster rules.

See [Prometheus Alerting](https://prometheus.io/docs/practices/alerting/) for
details on configuring alerts.

### Configure alert notifications

The default Alertmanager configuration in the
``cluster/addons/prometheus/prometheus-operator.yaml`` file is not configured to
send any alert notifications. Use the the ``alertmanager.config`` section in the
Prometheus operator Helm chart values file to configure alert notifications.

For more information, see
[Alertmanager Configuration](https://prometheus.io/docs/alerting/configuration/)
and
[Alertmanger Notifications](https://prometheus.io/docs/alerting/notifications/).

### Import custom Grafana dashboards

Grafana includes a set of predefined dashboards for viewing Kubernetes and
cluster metrics.  You can add custom dashboards to your deployment by adding
dashboard JSON files to the
``cluster/addons/prometheus/forgerock-metrics/dashboards`` directory.

### Expose Prometheus and Grafana externally

External access is enabled by default using the FQDNs,
``<prometheus|grafana|alertmanager>.iam.example.com``.

If you want to change the hostname, edit the
``<prometheus|grafana|alertmanager>.ingress.hosts`` value in the  
``prometheus-operator.yaml`` file.

The labels are optional, and the hostname and secret name align with the current
deployment of the CDM with cert-manager.
