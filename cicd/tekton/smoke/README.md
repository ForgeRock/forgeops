# Tekton smoke Test

Runs a smoke test deployment every time a commit is made to the forgeops repo.

## Pipeline overview

The `./install-pipeline.sh` script installs the pipeline and all other required elements in the `tekton-pipelines` namespace.

Note: The smoke pipeline is configured to trigger automatically when there's a push event in the master branch of our repo https://stash.forgerock.org/scm/cloud/forgeops.git. You must provide the webhook secret as a k8s generic secret named `git-webhook-secret` using `secret` as the key for the entry. You must use the same secret when creating the webhook. In addition to the secret, update `ingress.yaml` with the FQDN of your trigger endpoint.

You can use the following command to create the secret:

```bash
kubectl -n $NAMESPACE create secret generic git-webhook-secret --from-literal=secret=$WEBHOOK_SECRET
```

Tekton provides a github trigger interceptor that we have repurposed to work with bitbucket by using their CEL interceptors to change contents of the webhook POST request.

Recommended documentation:
1. Github webhook events: https://developer.github.com/v3/activity/events/types/#pushevent
2. Bitbutcket webhook events: https://confluence.atlassian.com/bitbucketserver0516/event-payload-966061436.html
3. Tekton triggers: https://github.com/tektoncd/triggers/blob/master/docs/eventlisteners.md#GitHub-Interceptors

The Tekton dashboard is included in this install. To map the dashboard, you can run:

```
# Map the svc port
kubectl --namespace tekton-pipelines port-forward svc/tekton-dashboard 9097:9097
# open http://localhost:9097 in your browser
```

## Manually Triggering the Pipeline

Because the eventlistener validates the request signatures, the easiest way to trigger the pipeline manually is to bypass the tekton trigger. You can manually re-run the pipeline using the following command:

```bash
tkn -n tekton-pipelines pipeline start smoke-pipeline -s tekton-worker #start a pipeline
```
Note: You'll need to provide information about your repo like url and branch/commit id.

