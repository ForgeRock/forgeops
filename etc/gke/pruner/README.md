# gcp pruner

Scripts to prune GCP resources.

Code can be run as a standalone script or as a Cloud Run service.

# gcr pruning

Prune's images (manifests) that are tagless from a docker registry.

The following conditions must be met:

1. The manifest is *NOT* tagged.
2. Image was last updated greater than `MAX_UPDATE_AGE` days ago
3. Special rules for forgerock-io images

The pruner operates on all repos that it has access to, so use bucket ACLs to control access for a registry. At the moment there's a hard coded exclude list that could become configurable

# disk pruning

Prunes block storage disks that are unattached and older that `MAX_DISK_AGE` which defaults to 30 days. `DRY_RUN=1` can be used to preview what would be deleted. The

## configuration

all through environment variabes as follows:

* `PORT` - must be set (automatic when run via Cloud Run)
* `GCR_PRUNE_DRY_RUN` =1 dry run =0 delete things (default: 0)
* `MAX_UPDATE_AGE` number of days since a manifest has been updates (default: 14)

# Running in GCP

## how it operates

1. A Google Cron Schedule is configured to send a message to a pubsub topic. (message body is moot)
2. A subscription does a POST to the cloud run url
3. URL will be routed to the appropriate pruning function which will return a 204 or 4XX

## installation

### service accounts

```
export PROJECT_ID=myproject
export PROJECT_NUM=41234
# allow automatic for POSTing to Cloud Run url
gcloud iam service-accounts create cloud-run-pubsub-invoker \
     --display-name "Cloud Run Pub/Sub Invoker"

# what the container runs as
gcloud iam service-accounts create gcp-pruner --display-name=gcp-pruner

# allow pruner access to the registry bucket
export PRUNER_SERVCE=gcp-pruner@$PROJECT_ID.iam.gserviceaccount.com
gsutil iam ch serviceAccount:gcp-pruner@$PROJECT_ID.iam.gserviceaccount.com:admin gs://artifacts.$PROJECT_ID.appspot.com

# make sure we can have auth tokens
gcloud projects add-iam-policy-binding $PROJECT_ID \
     --member=serviceAccount:service-$PROJECT_NUM@gcp-sa-pubsub.iam.gserviceaccount.com \
     --role=roles/iam.serviceAccountTokenCreator

# create role for disk pruner.
gcloud iam roles create GCPPruner --project=$PROJECT_ID \
                                  --title=GCPPruner \
                                  --description="GCP Pruner Role" \
                                  --permissions=compute.zones.list,compute.disks.delete,compute.disks.list 

# allow cloud build to run as service account for deployment
gcloud iam service-accounts add-iam-policy-binding \
      gcp-pruner@$PROJECT_ID.iam.gserviceaccount.com \
      --member="serviceAccount:$PROJECT_NUM@cloudbuild.gserviceaccount.com" \
      --role="roles/iam.serviceAccountUser"
```

### create service

```
gcloud run deploy gcp-pruner --image gcr.io/$PROJECT_ID/gcp-pruner:latest --platform managed --region us-east4 --no-allow-unauthenticated
```

### pubsub

```
# topic
gcloud pubsub topics create gcp-prune

# allow pubsub account to invoke service
gcloud run services add-iam-policy-binding gcp-pruner@$PROJECT_ID.iam.gserviceaccount.com \
   --member=serviceAccount:cloud-run-pubsub-invoker@$PROJECT_ID.iam.gserviceaccount.com \
      --role=roles/run.invoker

# setup registry and disk pruning subscriptions
gcloud pubsub subscriptions create registry-prune --topic gcp-prune \
   --push-endpoint=https://gcp-pruner-7escakmhgq-uk.a.run.app/registry \
   --push-auth-service-account=cloud-run-pubsub-invoker@$PROJECT_ID.iam.gserviceaccount.com
gcloud pubsub subscriptions create disk-prune --topic gcp-prune \
   --push-endpoint=https://gcp-pruner-7escakmhgq-uk.a.run.app/disks \
   --push-auth-service-account=cloud-run-pubsub-invoker@$PROJECT_ID.iam.gserviceaccount.com
```

### cronjob

```
gcloud scheduler jobs create pubsub weekly-gcp-prune --schedule="every saturday 09:00" --topic=gcp-prune --message-body="prune those images"
```

### Build and Deploy

```
gcloud builds submit
```
