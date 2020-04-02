# Tekton demo / poc

This demonstrates the use of tekton to build and deploy our nightly environment in a cluster using the skaffold and kaniko builder.
The entire build happens in the cluster itself. No external tooling is required.

## Pre-reqs

* Create a `kaniko-secret` in the default namespace. `kubectl create secret generic kaniko-secret --from-file=kaniko-secret`.
   The secret is the GCP service account json that has privileges to push/pull images to gcr.io
* Optional: install the tkn cli tool. More information: https://github.com/tektoncd/cli
  You can perform actions like:
    tkn -n nightly pipelinerun logs nightly-pipeline-run-lf7tn -f #get pipeline logs
    tkn -n nightly pipeline start nightly-pipeline -s tekton-worker #start a pipeline

## Run

Run the shell script `forgeops/cicd/tekton/install-tekton.sh` to install tekton in your cluster. Then, run `./install-pipeline.sh nightly`. This will install the pipeline and all other required elements in the `nightly` namespace.

Note: The nightly pipeline is configured to trigger automatically daily at 9:00 Mon-Fri ("* 9 * * 1-5"). If you want to change/remove this trigger, you can modify/remove nightly-trigger.yaml with the desired configuration.

The Tekton dashboard is included in this install. To map the dashboard, you can run:

```
# Map the svc port
kubectl --namespace tekton-pipelines port-forward svc/tekton-dashboard 9097:9097
# open http://localhost:9097 in your browser
```

## Manually Triggering the Pipeline

The pipeline is triggered by a Kubernetes Cronjob. You can manually re-run the pipeline using the following command:

```bash
tkn -n nightly pipeline start nightly-pipeline -s tekton-worker #start a pipeline
```
Note: You'll need to provide information about your repo like url and branch/commit id

If you don't have `tkn` installed, you can also start the pipeline by manually triggering the cronjob

```bash
kubectl -n nightly create job --from=cronjob/nightly-cronjob manual-run
```
