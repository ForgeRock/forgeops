# Tekton demo / poc

This demonstrates the use of tekton to build and deploy our nightly builds in the cluster using the skaffold and kaniko builder.
The entire build is done in the cluster itself. No external tooling is required.

## Pre-reqs

* Create a `kaniko-secret` in the default namespace. `kubectl create secret generic kaniko-secret --from-file=kaniko-secret`.
   The secret is the GCP service account json that has privileges to push/pull images to gcr.io
* Optional: install the tkn cli tool. More information: https://github.com/tektoncd/cli
  You can perform actions like:
    tkn pipelinerun logs nightly-pipeline-run-lf7tn -f -n nightly #get pipeline logs
    tkn -n nightly pipeline start nightly-pipeline -s tekton-worker #start a pipeline

## Run

Run the shell script `./install.sh`

This creates the Pipeline, Triggers, Tasks, Cronjoba, ServiceAccounts and all other required elements to create a functioning pipeline.

Note: This deployment will trigger automatically daily at 9:00 Mon-Fri ("* 9 * * 1-5"). If you want to change/remove this trigger, you can modify/remove nightly-trigger.yaml with the desired configuration.

You can also see the log output from the dashboard:

```
# Map the svc port
kubectl --namespace tekton-pipelines port-forward svc/tekton-dashboard 9097:9097
# open http://localhost:9097 in your browser
```
Or by using tkn cli tool

## Manually Triggering the Pipeline

The pipeline is triggered by a Kubernetes Cronjob. You can manually re-run the pipeline using the following command:

```bash
tkn -n nightly pipeline start nightly-pipeline -s tekton-worker #start a pipeline
```

If you don't have `tkn` installed, you can also start the pipeline by manually triggering the cronjob

```bash
kubectl -n nightly create job --from=cronjob/nightly-cronjob manual-run
```
