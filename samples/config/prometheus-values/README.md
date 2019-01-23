# Prometheus override values

The files in this directory are copies of etc/prometheus-values/kube-prometheus.yaml. They are used to provide cluster specific configuration.  
This file contains configuration values for Prometheus and Alertmanager and flags to switch off generating metrics for specific  
areas of the platform.

The main uses of this override file will be to:
* customize the Alertmanager configuration which determines whether to send alert notifications to a particular receiver(Slack for example).
* customize the Prometheus configuration to apply new endpoints to capture metrics from(for example: an additional service that's running alongside FR products). 

Documentation links are embedded into the override values files.

Full implementation details can be found in the foregrock-metrics Helm chart README.md.