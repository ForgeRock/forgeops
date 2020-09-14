# Gatling Benchmarks for the ForgeRock platform

This sample is provided for reference only and is not supported by ForgeRock. Use this at your own risk.

## Benchmark Configuration

* The utility class [BenchConfig](src/gatling/simulations/util.scala) initializes the common parameters for the test (number of users, duration, etc.). These are derived from environment variables. To override the default values, set these env variables in your env or script before running the simulations.  

* Pre-existing passwords for setting into env variables can be printed using the forgeops/bin/print-secrets.sh script.  For the IDM simulations you can get the secrets via `$ kubectl exec -it am-6f95c6bd4-vlsgn -- env | grep IDM_PROVISIONING_CLIENT_SECRET`

* The [run-all.sh](run-all.sh) script sets these variables if they are not already set elsewhere. When running in Kubernetes, the [ConfigMap in perf-test](k8s/perf-test-job.yaml)  sets these values.




## Running Locally

You can run the gatling benchmarks from your laptop if you have both Gradle and Docker installed. This has been tested with OpenJDK 11 and Gradle 6.5.1. 

=> Don't forget to set the Benchmark Configuration via env variables first as described in the previous section.

To run all simulations:

```
$ ./run-all.sh
```

To run individual simulations

```
$ gradle clean && gradle gatlingRun-am.AMAccessTokenSim
```

The following simulations are provided in the src/gatling/simulations folder:

|Simulation|Description
|----------|-----------
|am.AMRestAuthNSim|A simulation of the basic AM REST /json/authenticate endpoint for authentication
|am.AMAccessTokenSim|A simulation to issue OAuth 2.0 access_token using the auth code flow
|idm.IDMSimulation70|This idm simulation creates and deletes test users
|platform.Register|This simulation mimics an interactive user registration
|platform.Login|This simlation mimics an interactive user login. The *platform.Register* simulation is a *pre-requisite* for this simuation. This simulation using an Authentication Tree called "Login" which in turn uses the "Progressive Profiling" tree.
|*ig.\**|*These simulaitons are no longer maintained.  Use them at your own risk*

If you just want to compile the simulation code:

```
$ gradle gatlingClasses
```




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
$ skaffold [--default-repo gcr.io./engineering-devops] run
```

or use `dev` instead of `run` to see the output.

At the conclusion of the benchmark jobs, the results will be uploaded to:

https://console.cloud.google.com/storage/browser/forgeops-gatling?project=engineering-devops

See the [k8s deployment](k8s/) folder to modify the deployment. 

## GCS Service Account Configuration

The gradle task ` gradle uploadResults` will zip up the benchmark results and upload them to the gcs bucket `gs://forgeops-gatling`. This task is run at the conclusion of the Kubernetes perf-test job.

The task needs a service account to upload Gatling results to a GCS bucket. If you are running locally using gradle, you do NOT need the service account unless you want to test the GCS upload process.

The service account file `key.json` is NOT checked in to git.  Create and download a key from https://console.cloud.google.com/iam-admin/serviceaccounts (or see Warren to get a copy of the key.json)

Place the key.json in: `k8s/key.json`. The environment variable
`GOOGLE_APPPLICATION_CREDENTIALS` must point to this file (see `run-all.sh`).

