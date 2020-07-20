# Tekton pipelines

This demonstrates the use of tekton to build and deploy environments in a cluster using the skaffold and kaniko builder.
The entire build is done in the cluster itself. No external tooling is required.

## Pre-reqs

* Create a `kaniko-secret` in the default namespace. `kubectl create secret generic kaniko-secret --from-file=kaniko-secret`.
   The secret is the GCP service account json that has privileges to push/pull images to gcr.io
* Optional: install the tkn cli tool. More information: https://github.com/tektoncd/cli
  You can perform actions like:
    tkn pipelinerun logs nightly-pipeline-run-lf7tn -f -n nightly #get pipeline logs
    tkn -n nightly pipeline start nightly-pipeline -s tekton-worker #start a pipeline

## Run

Run the shell script `forgeops/cicd/tekton/install-tekton.sh` to install tekton in your cluster. Then, run the `install-pipeline.sh` script for each desired pipeline.

The Tekton dashboard is also included in this install. To map the dashboard, you can run:

```bash
# Map the svc port
kubectl --namespace tekton-pipelines port-forward svc/tekton-dashboard 9097:9097
# open http://localhost:9097 in your browser
```

## Purging completed pods

Tekton leaves completed pods around to provide status updates and for log output. After several days
you may wish to clean up completed pods. Use the following command:


```
kubectl -n tekton-pipelines delete pod --field-selector=status.phase==Succeeded
```
