# Tekton fidc Deployment

This sample pipeline demonstrates the use of Tekton to build and deploy our
fidc environment using Skaffold and Kaniko.

The entire build happens in the cluster itself. No external tooling is required.
All persistent data is deleted, and the environment is deployed fresh every 24
hours.

The fidc pipeline is configured to trigger automatically daily at 9:00
Mon-Fri (`"0 9 * * 1-5"`). To change this trigger, modify the
`cicd/tekton/fidc/fidc-trigger.yaml` file, providing your desired
configuration.

## Manually Triggering the Pipeline

The pipeline is triggered by a Kubernetes cron job. You can manually run the
pipeline using the following command:

```bash
tkn -n tekton-pipelines pipeline start fidc-pipeline -s tekton-worker #start a pipeline
```

You'll need to provide the repository URL, branch, and commit ID.

If you don't have the `tkn` command installed, you can also start the pipeline
by manually triggering the cron job:

```bash
kubectl -n tekton-pipelines create job --from=cronjob/fidc-cronjob manual-run
```
