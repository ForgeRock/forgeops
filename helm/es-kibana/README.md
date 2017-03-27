# Elasticsearch / Kibana chart

This runs a development (single master) ES instance along with Kibana.


ES runs without security on an internal cluster IP on port 9200. For this reason, it has not been exposed
externally via an ingress. If you want to access Kibana, find the pod for ES, and run:

kubectl port-forward es-pod-xxxx 5601:5601

Then point your browser to http://localhost:5601

See https://bugster.forgerock.org/jira/browse/OPENIDM-5199 for some sample Kibana reports.

The config/ directory contains a shell script that will create the audit index,
and a sample Kibana dashboard in export.json.

Run: kubectl port-forward es-pod-xxxx 9200:9200

then run the audit-index.sh script.

The export.json can be imported into the Kibana dashboard using the GUI.



