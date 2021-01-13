# Tekton Smoke Test

This sample pipeline runs a smoke test deployment every time a commit is made to
the `forgeops` repo.

## Pipeline Overview

The `./install-pipeline.sh` script installs the pipeline and all other required 
elements in the `tekton-pipelines` namespace.

The smoke test pipeline is configured to trigger automatically when there's a 
push event in the master branch of our repo, 
https://stash.forgerock.org/scm/cloud/forgeops.git. You must provide the webhook
secret as a Kubernetes generic secret named `git-webhook-secret`, using `secret` 
as the key for the entry. You must use the same secret when creating the 
webhook. In addition to creating the secret, you must update the `ingress.yaml` 
file with the FQDN of your trigger endpoint.

You can use the following command to create the secret:

```bash
kubectl -n $NAMESPACE create secret generic git-webhook-secret --from-literal=secret=$WEBHOOK_SECRET
```

Tekton provides a GitHub trigger interceptor. We've repurposed this trigger to 
work with Bitbucket by using their CEL interceptors to change the contents of 
the webhook's POST request.

Recommended documentation:

* [GitHub webhook events](https://developer.github.com/v3/activity/events/types/#pushevent)
* [Bitbutcket webhook events](https://confluence.atlassian.com/bitbucketserver0516/event-payload-966061436.html)
* [Tekton triggers](https://github.com/tektoncd/triggers/blob/master/docs/eventlisteners.md#GitHub-Interceptors)

The Tekton dashboard is included in this installation. To map the dashboard, 
run:

```
# Map the svc port
kubectl --namespace tekton-pipelines port-forward svc/tekton-dashboard 9097:9097
# open http://localhost:9097 in your browser
```

## Manually Triggering the Pipeline

Because the event listener validates the request signatures, the easiest way to 
trigger the pipeline manually is to bypass the Tekton trigger. You can manually
rerun the pipeline using the following command:

```bash
tkn -n tekton-pipelines pipeline start smoke-pipeline -s tekton-worker #start a pipeline
```
You'll need to provide the repository URL, branch, and commit ID.

