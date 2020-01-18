# Gatling Benchmarks for the ForgeRock platform

This sample is provided for reference only and is not supported 
by ForgeRock. Use this at your own risk.

## Running Locally

You can run the gatling benchmarks from your laptop if you have gradle installed. This
has been tested with OpenJDK 11 and Gradle 5.6.2.

To run the simulations:
```
# The idm simulations create and delete test users. You can use this for evaluating the create and delete user 
# benchmarks but for benchmarking AM, users should be generated using the DS make_users.sh in the idrepo container.
gradle gatlingRun-idm.IDMReadCreateUsersSim65
gradle gatlingRun-idm.IDMDeleteUsersSim65
# TODO: 7.0 IDM benchmarks

# A test of the basic AM REST /json/authenticate endpoint
gradle gatlingRun-am.AMRestAuthNSim
# A test to issue access tokens using the auth code flow.
gradle gatlingRun-am.AMAccessTokenSim
```

If you just want to compile the simulation code:

```
gradle gatlingClasses
```

## Benchmark Parameters.

The utility class  [BenchConfig])(src/gatling/simulations/util) initializes the common parameters for
the test (number of users, duration, etc.). These are derived from environment variables. 

The [run-all.sh](run-all.sh) script sets these variables if they are not already set elsewhere. When 
running in Kubernetes, the [ConfigMap in perf-test](k8s/perf-test-job.yaml)  sets these values.


## Enabling debug output 

See the [logback.xml](src/gatling/resources/logback.xml) file to enable tracing of 
the http calls. Tracing is *very* verbose and should only be turned on 
when debugging. 

To enable results output in gatling
edit [gatling.conf](src/gatlinge/resources/gatling.conf) and add `console` to the
writers list:

```json
gatling {
  data {
    writers = [file, console]
  }
}
```

## Running with skaffold / docker

You can deploy these benchmarks in a Kubernetes cluster. It does not need to be
the same cluster as your test target as the benchmark uses the external 
FQDN. 

Deploy using:
```
skaffold [--default-repo gcr.io./engineering-devops] run
```

or use `dev` instead of `run` to see the output.

At the conclusion of the benchmark jobs, the results will be uploaded to:

https://console.cloud.google.com/storage/browser/forgeops-gatling?project=engineering-devops

See the [k8s deployment](k8s/) folder to modify the deployment. 

## GCS Service Account Configuration

The gradle task ` gradle uploadResults` will zip up the benchmark results and upload them
to the gcs bucket `gs://forgeops-gatling`. This task is run at the conclusion 
of the Kubernetes perf-test job.

The task needs a service account to upload Gatling results to a GCS bucket. If you are
 running locally using gradle, you do NOT need the service account unless you want to test the GCS upload process.

The service account file `key.json` is NOT checked in to git.  Create and download a key
from https://console.cloud.google.com/iam-admin/serviceaccounts
 (or see Warren to get a copy of the key.json)

Place the key.json in: `k8s/key.json`. The environment variable
`GOOGLE_APPPLICATION_CREDENTIALS` must point to this file (see `run-all.sh`).

