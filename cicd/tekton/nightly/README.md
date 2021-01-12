# Tekton Nightly Deployment

This demonstrates the use of Tekton to build and deploy our nightly environment using the skaffold and kaniko.

The entire build happens in the cluster itself. No external tooling is required. All persistent data is deleted
and the environment is deployed fresh every 24 hours.

 The nightly pipeline is configured to trigger automatically daily at 9:00 Mon-Fri ("0 9 * * 1-5"). If you want to change/remove this trigger, you can modify/remove nightly-trigger.yaml with the desired configuration.

## Manually Triggering the Pipeline

The pipeline is triggered by a Kubernetes Cronjob. You can manually re-run the pipeline using the following command:

```bash
tkn -n tekton-pipelines pipeline start nightly-pipeline -s tekton-worker #start a pipeline
```
Note: You'll need to provide information about your repo like url and branch/commit id

If you don't have `tkn` installed, you can also start the pipeline by manually triggering the cronjob

```bash
kubectl -n tekton-pipelines create job --from=cronjob/nightly-cronjob manual-run
```
