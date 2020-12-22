# Google Cloud Pruner

Scripts used by ForgeRock to manage our Google Cloud resources.

The code can be run as a standalone script or as a Google Cloud Run service.

# GCR Pruning

The pruner operates on all repositories that it has access to. Use bucket ACLs 
to control access for a registry. 

# Disk Pruning

The pruner removes block storage disks that are unattached, and older than 
`MAX_DISK_AGE` days. `MAX_DISK_AGE` is set in an environment variable when you 
run the pruner.

# Configuration

Configure the pruner by setting the following environment variables:

* `PORT` - Must be set if you're not using Cloud Run.
  
* `DRY_RUN` - Preview which disks would be deleted during disk pruning. Set to
1 for a dry run; 0 for actual deletion.  
  
* `GCR_PRUNE_DRY_RUN` - Preview which Docker images would be deleted during GCR
pruning. Set to 1 for a dry run; 0 for actual deletion.
  
* `MAX_UPDATE_AGE` - A number of days. Delete manifests that were last updated 
more than `MAX_UPDATE_AGE` days ago. The default is 14.
  
* `MAX_DISK_AGE` - A number of days. Delete unattached disks that were created 
more than `MAX_DISK_AGE` days ago. The default is 30.

# Running in GCP

## How it Operates

1. A Google cron schedule is configured to send a message to a pubsub topic. 
(The message body is irrelevant.)
   
2. A subscription POSTs to the Cloud Run URL.
   
3. The URL is routed to the appropriate pruning function, which will return a 
204 or 4XX.

## Installation

### Service Accounts

```
export PROJECT_ID=myproject
export PROJECT_NUM=41234
# Allow automatic for POSTing to Cloud Run URL
gcloud iam service-accounts create cloud-run-pubsub-invoker \
     --display-name "Cloud Run Pub/Sub Invoker"

# What the container runs as
gcloud iam service-accounts create gcp-pruner --display-name=gcp-pruner

# Allow pruner access to the registry bucket
export PRUNER_SERVCE=gcp-pruner@$PROJECT_ID.iam.gserviceaccount.com
gsutil iam ch serviceAccount:gcp-pruner@$PROJECT_ID.iam.gserviceaccount.com:admin gs://artifacts.$PROJECT_ID.appspot.com

# Make sure we can have auth tokens
gcloud projects add-iam-policy-binding $PROJECT_ID \
     --member=serviceAccount:service-$PROJECT_NUM@gcp-sa-pubsub.iam.gserviceaccount.com \
     --role=roles/iam.serviceAccountTokenCreator

# Create a role for the disk pruner
gcloud iam roles create GCPPruner --project=$PROJECT_ID \
                                  --title=GCPPruner \
                                  --description="GCP Pruner Role" \
                                  --permissions=compute.zones.list,compute.disks.delete,compute.disks.list 

# Allow Cloud Build to run as a service account for deployment
gcloud iam service-accounts add-iam-policy-binding \
      gcp-pruner@$PROJECT_ID.iam.gserviceaccount.com \
      --member="serviceAccount:$PROJECT_NUM@cloudbuild.gserviceaccount.com" \
      --role="roles/iam.serviceAccountUser"
```

### Create the Service

```
gcloud run deploy gcp-pruner --image gcr.io/$PROJECT_ID/gcp-pruner:latest --platform managed --region us-east4 --no-allow-unauthenticated
```

### Pubsub

```
# Topic
gcloud pubsub topics create gcp-prune

# Allow the pubsub account to invoke service
gcloud run services add-iam-policy-binding gcp-pruner@$PROJECT_ID.iam.gserviceaccount.com \
   --member=serviceAccount:cloud-run-pubsub-invoker@$PROJECT_ID.iam.gserviceaccount.com \
      --role=roles/run.invoker

# Setup registry and disk pruning subscriptions
gcloud pubsub subscriptions create registry-prune --topic gcp-prune \
   --push-endpoint=https://gcp-pruner-7escakmhgq-uk.a.run.app/registry \
   --push-auth-service-account=cloud-run-pubsub-invoker@$PROJECT_ID.iam.gserviceaccount.com
gcloud pubsub subscriptions create disk-prune --topic gcp-prune \
   --push-endpoint=https://gcp-pruner-7escakmhgq-uk.a.run.app/disks \
   --push-auth-service-account=cloud-run-pubsub-invoker@$PROJECT_ID.iam.gserviceaccount.com
```

### Cron Job

```
gcloud scheduler jobs create pubsub weekly-gcp-prune --schedule="every saturday 09:00" --topic=gcp-prune --message-body="prune those images"
```

### Build and Deploy

```
gcloud builds submit
```
