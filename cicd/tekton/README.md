# Tekton Pipelines

The artifacts in the directory provide an example of how you might use 
[Tekton](https://tekton.dev) to build and deploy environments in a cluster using
Skaffold and Kaniko. The entire build is done in the cluster itself. No external
tooling is required.

## Prerequisite

Create a Kubernetes secret named `kaniko-secret` in the default namespace. The
secret must contain the JSON for a GCP service account with privileges to push
and pull images to gcr.io. See the `cicd/bin/gke-kaniko.sh` script for an 
example that creates the service account and the secret.

## Install Software 

* Install the latest Tekton release, including the dashboard, from tekton.dev. 
  See the `cicd/bin/install-tekton.sh` script for an example.

* (Optional) Install the `tkn` CLI tool. This tool lets you perform actions 
  like getting the pipeline logs and starting a pipeline. More information
  [here](https://github.com/tektoncd/cli).

## Install Pipelines

Run the `install-pipeline.sh` script for each desired pipeline in the 
`cicd/tekton/<pipeline>` directory.

To access the Tekton dashboard, run the `cicd/bin/dashboard.sh` script and go 
to http://localhost:9097 in your browser.

## Purging Completed Pods

Tekton leaves completed pods for status updates and log output. After several 
days, you might want to clean up completed pods. Use the following command:

```
kubectl -n tekton-pipelines delete pod --field-selector=status.phase==Succeeded
```