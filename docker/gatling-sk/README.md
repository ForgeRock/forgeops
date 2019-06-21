# Gatling Benchmarks for the ForgeRock platform

This sample is forgerock internal and relies on a specific GKE configuration. It is not
supported by ForgeRock. Use this at your own risk.

## Running Locally

You can run the gatling benchmarks from your laptop if you have gradle installed.

Try:
```
gradle gatlingRun-idm.IDMSimulation
gradle gatlingRun-am.AMRestAuthNSim
``
See the varioous gatling simulations for details on how to configure the target host name, etc.

If you just want to compile the simulation code:

```
gradle gatlingClasses
```


## Running on the cloud with skaffold / docker

Deploy using:
```
cd ../
skaffold -f skaffold-gatling.yaml [--default-repo gcr.io./engineering-devops] run
```

or use `dev` instead of `run` to see the output.

This will run the benchmark (see the ../kustomize/gatling artifacts for the cli used to launch the benchmark). At
the conclusion of the benchmark jobs, the results will be uploaded to:

https://console.cloud.google.com/storage/browser/forgeops-gatling?project=engineering-devops

## Service Account Configuration

You need a service account to enable the pods to upload Gatling results to a GCS bucket. If you are
 running locally using gradle, you do NOT need the service account unless you want to test the GCS upload process.


The service account `key.json` is NOT checked in to git.  Create and download a key
from https://console.cloud.google.com/iam-admin/serviceaccounts
 (or see Warren to get a copy of the key.json)

Place the key.json in:

- `./key.json` (for running locally, only if you want to test upload to GCS)
- `../kustomize/gatling/key.json`  (for running in GKE)

## Credit

Configuration inspired by this [article](https://medium.com/de-bijenkorf-techblog/https-medium-com-annashepeleva-distributed-load-testing-with-gatling-and-kubernetes-93ebce26edbe).