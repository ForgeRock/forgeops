# GCR Cleaner

Build/Deploy configuration for the [open source project](https://github.com/sethvargo/gcr-cleaner) cleaning images from GCR.

Directory Structure
```
etc/gcr-cleaner
├── bin
│   ├── install-cloudbuild-trigger
│   └── install-gcr-cleaner-plumbing
├── cloudbuild.yaml
└── README.md
```

## Installation

These steps should happen once per GCP project.

1. Assumption: Cloud Build must be enabled, it should be have SchedulAdmin role added to it and the service account act as in build settings. These scripts do not setup basic cloud build configuration within a project. If there's an issue with permissions the error messages are usually pretty clear.

2. Create project plumbing. this should be done once per project. This will create a cloud run deployment, pubsub topic/subscription, initialize the service and service accounts/grants.
```
./etc/gcr-cleaner/bin/install-gcr-cleaner-plumbing
```
3. Create the cloud build trigger. The trigger is for continious deployment of the prunner on any change to its configuration.
```
./etc/gcr-cleaner/bin/install-cloudbuild-trigger
```
4. Manually create the first deployemt. This will update the cleaner service as well as create the scheduled job.
```
gcloud --project <my-project> builds submit --substitutions=_GCR_CLEANER_COMMIT=v0.5.0 --config etc/gcr-cleaner/cloudbuild.yaml
```

## Configuring a cleaning schedule

1. Assumption: You've read the `gcr-cleaner` README.md.
2. Append the final step of cloudbuild.yaml with your configuration, recommended that you test with `dry_run: true`. To test, make the change in cloudbuild.yaml and then run Installation step 4.
3. Open PR against ForgeOps with the change.
