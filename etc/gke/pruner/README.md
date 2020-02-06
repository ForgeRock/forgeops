# gcr pruner

Prune's images (manifests) that are tagless from a docker registry.

## how it operates

1. A Google Cron Schedule is configured to send a message to a pubsub topic. (message body is moot)
2. A subscription does a POST to the cloud run job
3. The POST starts the pruner container, which calls the catalog endpoint on the registry and then checks all repos in the registry for images that should be pruned, then deletes manifests.

## prune logic

The following conditions must be met:

1. The manifest is *NOT* tagged.
2. Image was last updated greater than `MAX_UPDATE_AGE` days ago

The pruner operates on all repos that it has access to, so use bucket ACLs to control access for a registry. At the moment there's a hard coded exclude list that could become configurable

## configuration

all through environment variabes as follows:

* `PORT` - must be set (automatic when run via Cloud Run)
* `GCR_PRUNE_DRY_RUN` =1 dry run =0 delete things (default: 0)
* `MAX_UPDATE_AGE` number of days since a manifest has been updates (default: 14)

# infrastructure

## service accounts

```
# allow automatic for POSTing to Cloud Run url
gcloud iam service-accounts create cloud-run-pubsub-invoker \
     --display-name "Cloud Run Pub/Sub Invoker"

# what container runs as
gcloud iam service-accounts create gcr-pruner --display-name=gcr-pruner

# allow pruner access to the registry bucket
gsutil iam ch serviceAccount:gcr-pruner@engineering-devops.iam.gserviceaccount.com:admin gs://artifacts.PROJECT-ID.appspot.com

# make sure we can have auth tokens
gcloud projects add-iam-policy-binding PROJECT-ID \
     --member=serviceAccount:service-PROJECT-NUMBER@gcp-sa-pubsub.iam.gserviceaccount.com \
    --role=roles/iam.serviceAccountTokenCreator
gcloud run services add-iam-policy-binding gcr-pruner \
   --member=serviceAccount:cloud-run-pubsub-invoker@PROJECT-ID.iam.gserviceaccount.com \
   --role=roles/run.invoker
```

## pubsub

```
# topic
gcloud pubsub topics create gcr-prune

# subscription
gcloud pubsub subscriptions create gcr-prune-subscription --topic gcr-prune \
   --push-endpoint=SERVICE-URL/ \
   --push-auth-service-account=cloud-run-pubsub-invoker@PROJECT-ID.iam.gserviceaccount.com
```
## cron job

```
gcloud scheduler jobs update pubsub weekly-gcr-prune --schedule="every saturday 09:00" --topic=gcr-prune --message-body="prune those images"
```

# Build and Deploy

```
gcloud builds submit
```
