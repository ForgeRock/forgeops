# Gatling Benchmarks for the ForgeRock platform

This sample is provided for reference only and is not supported by ForgeRock. Use this at your own risk.

## Benchmark Configuration

* The utility class [BenchConfig](src/gatling/simulations/util.scala) initializes the common parameters for the test (number of users, duration, etc.). These are derived from environment variables. Override the default values and set these env variables in your shell env or script before running the simulations. <u>This is a critical step which missed will lead to all sorts of failures</u>.

* Pre-existing passwords for setting into env variables can be printed using the `forgeops/bin/print-secrets.sh` script.  For the simulations that require provisioning into IDM you will also need the you can get the secrets for the "idm-provisioning" OAuth2 client via the following command. `$ kubectl exec -it am-6f95c6bd4-vlsgn -- env | grep IDM_PROVISIONING_CLIENT_SECRET`

* The [run.sh](run.sh) script sets these variables if they are not already set elsewhere. So you can also edit the env vars in this script. When running in Kubernetes, the [ConfigMap in perf-test](k8s/perf-test-job.yaml) can also set these values. See the section below called [Running in the Cluster](##Running in the Cluster).


## Simulations

The following sample simulations are provided in the src/gatling/simulations folder:

|Simulation|Description
|----------|-----------
|am.AMRestAuthNSim|A simulation of the basic AM REST /json/authenticate endpoint for authentication.
|am.AMAccessTokenSim|A simulation to issue OAuth 2.0 access_token using the auth code flow.
|idm.IDMSimulation|This idm simulation creates and optionally deletes test users.  The deletion is triggered by env variable DELETE_USERS=true which is set to false by default.
|platform.Register|This simulation mimics an interactive user registration.  Since this simulation creates new users it is recommended to set a different USER_PREFIX so that they do not collide with existing users that are seeded in the Identity Repository.
|platform.Login|This simulation mimics an interactive user login. This simulation using an Authentication Tree called "Login" which in turn uses the "Progressive Profiling" tree.
|*ig.\**|*These simulaitons are no longer maintained or tested.  Use them at your own risk*.

NOTE each of these simulation sets are independant of each other.  For example you can run the "idm" simulation without running the "am" simulations.  However the "platform" Login simulation depends on the Register simulation.  <u>You have to run the platform.Register simulation first so that the users created can be used by the Login simuation</u>.  Furthermore you have to ensure that you run the Register simulation long enough to provide the desired USER_POOL for the Login simulation otherwise you will start getting 401 errors.

If you just want to compile the simulation code:

```
$ gradle gatlingClasses
```


## Running Locally

You can run the gatling benchmarks from your laptop/desktop if you have both Gradle and Docker installed. This has been tested with OpenJDK 11 and Gradle 6.5.1. 

=> Don't forget to set the Benchmark Configuration via env variables first as described in the previous section.

To run simulations proivde as argument the type of simuation. Currently supported types are "all", "am", "idm" and "platform". For example:

```
$ ./run.sh am
```

To run simulations directly using gradle

```
$ gradle clean && gradle gatlingRun-am.AMAccessTokenSim
```



## Running in the Cluster
You can deploy these benchmarks in a Kubernetes cluster. It does not need to be
the same cluster as your test target as the benchmark uses the external 
FQDN. A pre-requisite to this step is ensuring that your GCS Service Account key copied locally. See the next section on configuration details. In addition ensure that the `TARGET_HOST`, `USER_POOL`, `DURATION`, `CONCURRRENCY`, `CLIENT_PASSWORD`, `IDM_PASSWORD` and `PERF_TEST_RESULTS_BUCKET_NAME` are set correctly in `k8s/perf-test-job.yaml`.

Deploy using:

```
$ skaffold --default-repo gcr.io/engineering-devops run
```

or use `dev` instead of `run` to see the output.

At the conclusion of the benchmark jobs, the results will be uploaded to the storage bucket specefied in `gsutil.scala`.

See the [k8s deployment](k8s/) folder to modify the deployment. 

## GCS Service Account Configuration

The gradle task `gradle uploadResults` will zip up the benchmark results and upload them to the gcs bucket. This task is run at the conclusion of the Kubernetes perf-test job.

The task needs a service account to upload Gatling results to a GCS bucket. If you are running locally using gradle, you do NOT need the service account unless you want to test the GCS upload process.

The service account file `key.json` is NOT checked in to git.  Create and download a key from https://console.cloud.google.com/iam-admin/serviceaccounts (or see Warren to get a copy of the key.json)

Place the key.json in: `k8s/key.json`. The environment variable
`GOOGLE_APPPLICATION_CREDENTIALS` must point to this file (see `run.sh`).

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


## Troubleshooting

=> If you see these errors during the simulations, make sure that the username and passwords are correct. For example check the values of `IDM_USER`, `IDM_PASSWORD` and `CLIENT_PASSWORD`.

- Request 'registationCallback' failed for user 1: jsonPath($.tokenId).find.exists, found nothing
- Request 'Submit Credentials' failed for user 1: status.find.is(200), but actually found 401


=> When deploying the "gatling" container to the cluster via skaffold, you will see this error if a k8s/key.json is not created 

``` 
stderr: "Error: file sources: [key.json]: evalsymlink failure on '/Users/wajih.ahmed/work/forgeops/docker/gatling/k8s/key.json' : lstat /Users/wajih.ahmed/work/forgeops/docker/gatling/k8s/key.json: no such file or directory\n"
```
And if key.json is invalid then you will see the following in the output of the Skaffold.

```
[perf-test] Exception in thread "main" com.google.cloud.storage.StorageException: 401 Unauthorized
```
=> While running a simulation if you see this error, it means you need to increase your feeder size by increasing the USER_POOL or reduce the DURATION of your simulation so that the feeder is not exhausted.

```
09:02:12.566 [ERROR] i.g.c.a.SingletonFeed - Feed failed: Feeder is now empty, stopping engine, please report.
```