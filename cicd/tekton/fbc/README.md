# Tekton demo / poc

This demonstrates the use of tekton to build and deploy our fbc environment in a cluster using the skaffold and kaniko builder.
The entire build happens in the cluster itself. No external tooling is required.

## Pre-reqs

* Create a `kaniko-secret` in the default namespace. `kubectl create secret generic kaniko-secret --from-file=kaniko-secret`.
   The secret is the GCP service account json that has privileges to push/pull images to gcr.io
* Optional: install the tkn cli tool. More information: https://github.com/tektoncd/cli  
  You can perform actions like trigger pipeplines runs or obtain pipeline logs:  
    tkn -n tekton-pipelines pipelinerun logs fbc-pipeline-run-lf7tn -f #get pipeline logs  
    tkn -n tekton-pipelines pipeline start fbc-pipeline -s tekton-worker #start a pipeline  
  For more information on `tkn`, take a look at https://github.com/tektoncd/cli/tree/master/docs

## Install the pipeline

Run the shell script `forgeops/cicd/tekton/install-tekton.sh` to install tekton in your cluster. Then, run `./install-pipeline.sh`. This will install the pipeline and all other required elements in the `tekton-pipelines` namespace.

Note: The fbc pipeline is configured to trigger automatically daily at 9:15 Mon-Fri ("15 9 * * 1-5"). If you want to change/remove this trigger, you can modify/remove fbc-trigger.yaml with the desired configuration.

The Tekton dashboard is included in this install. To map the dashboard, you can run:

```
# Map the svc port
kubectl --namespace tekton-pipelines port-forward svc/tekton-dashboard 9097:9097
# open http://localhost:9097 in your browser
```

## Manually Triggering the Pipeline

The pipeline is triggered by a Kubernetes Cronjob. You can manually re-run the pipeline using the following command:

```bash
tkn -n tekton-pipelines pipeline start fbc-pipeline -s tekton-worker #start a pipeline
```
Note: You'll need to provide information about your repo like url and branch/commit id

If you don't have `tkn` installed, you can also start the pipeline by manually triggering the cronjob

```bash
kubectl -n tekton-pipelines create job --from=cronjob/fbc-cronjob manual-run
```
