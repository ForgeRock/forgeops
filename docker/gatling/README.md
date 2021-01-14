# Gatling Benchmarks for the ForgeRock Identity Platform

This sample is provided for reference only, and is not supported by ForgeRock. 
Use this at your own risk.

## Benchmark Configuration

* The [BenchConfig](src/gatling/simulations/util.scala) utility class 
  initializes common parameters for simulation tests - number of users, 
  duration, etc.). These parameters are derived from environment variables. 
  Override the default values and set these environment variables in your shell 
  or script before running the simulations. <u>This is a critical step which, if 
  missed, will lead to failures</u>.

* Get administrative passwords by running the 
  [print-secrets](../../bin/print-secrets.sh) script.  
  
* The simulations that require provisioning to IDM also need the secrets for the
  `idm-provisioning` OAuth2 client. Obtain them by running:
  ```
  kubectl exec -it am-6f95c6bd4-vlsgn -- env | grep IDM_PROVISIONING_CLIENT_SECRET`
  ```

* The [`run.sh`](run.sh) script sets these variables if they are not already set 
  elsewhere. You can also edit the script to set the enviroment variables. When
  running in Kubernetes, you can also set these values in the config map in the
  [perf-test-job.yaml](k8s/perf-test-job.yaml) file. 
  
## Simulations

The following sample simulations are provided in the `src/gatling/simulations` 
directory:

|Simulation|Description
|----------|-----------
|`am/AMRestAuthNSim`|Calls the `/json/authenticate` endpoint for authentication.
|`am/AMAccessTokenSim`|Issues OAuth 2.0 access tokens using the auth code flow.
|`idm/IDMSimulation`|Creates and optionally deletes IDM test users. Deletion is triggered by setting the `DELETE_USERS` environment variable to `true`. (By default, it's set to `false`.)
|`platform/Register`|Mimics an interactive user registration. Since this simulation creates new users, it is recommended to set the `USER_PREFIX` environment variable, so that the new user IDs don't collide with existing user Ds seeded in the identity repository.
|`platform/Login`|Mimics an interactive user login using an authentication tree named `Login`. This tree uses the `Progressive Profiling` tree. You must run the `platform.Register` simulation before attempting to run this simulation, because this simulation requires users created by the `platform.Register` simulation.
|`ig/*`|IG simulations. These simulations are no longer maintained or tested. 

Except as noted, each of these simulation sets are independent from one another. 
For example, you can run `IDMSimulation` without running either of the AM 
simulations.  

To compile the simulation code:

```
gradle gatlingClasses
```

## Running Locally

You can run the Gatling benchmarks locally if you have both Gradle and Docker 
installed. See 
[the documentation](https://ea.forgerock.com/docs/forgeops/deployment/benchmark/authrate.html)
for examples.

## Running in a Cluster

You can run these benchmarks in a Kubernetes cluster. It does not need to be
the same cluster as your test target - the benchmark uses an external FQDN. 
Before you attempt to run the benchmarks in a cluster, make sure that your GCS  
Service Account key is copied locally. See 
[GCS Service Account Configuration](#gcs-service-account-configuration) for 
configuration details. In addition, ensure that the `TARGET_HOST`, `USER_POOL`, 
`DURATION`, `CONCURRRENCY`, `CLIENT_PASSWORD`, `IDM_PASSWORD` and 
`PERF_TEST_RESULTS_BUCKET_NAME` keys are set correctly in the 
`k8s/perf-test-job.yaml` file.

To run the benchmarks in a cluster:

```
skaffold --default-repo gcr.io/engineering-devops run
```

Alternatively, you can use `skaffold dev` to see the output.

At the conclusion of the benchmark jobs, the results are uploaded to the storage
bucket specefied in `gsutil.scala`.

See the [k8s deployment](k8s/) folder to modify the deployment. 

## GCS Service Account Configuration

Run `gradle uploadResults` to zip the benchmark results files and upload them to
the GCS bucket at the conclusion of the Kubernetes `perf-test` job.

The task needs a service account to upload Gatling results to a GCS bucket. If 
you're running locally, you don't need the service account, unless you want to 
test the GCS upload process.

Do not check your service account file, `key.json`, into your Git repository. 
Instead, create and download a key from 
[Google Cloud Console](https://console.cloud.google.com/iam-admin/serviceaccounts).
Place the `key.json` file in: `gatling/k8s/key.json`. The environment variable
`GOOGLE_APPPLICATION_CREDENTIALS` must point to this file. See the `run.sh` 
script for details.

## Enabling debug output 

See the [logback.xml](src/gatling/resources/logback.xml) file to enable tracing
the HTTP calls. Tracing is very verbose, and should only be turned on when 
debugging. 

To enable results output in Gatling, edit the 
[gatling.conf](src/gatling/resources/gatling.conf) file. Add `console` to the
writers list:

```json
gatling {
  data {
    writers = [file, console]
  }
}
```

## Troubleshooting

* These errors appear when running the simulations if the username and passwords
are incorrect. Check the values of `IDM_USER`, `IDM_PASSWORD` and 
`CLIENT_PASSWORD` if you see these messages:
    ```  
    Request 'registationCallback' failed for user 1: jsonPath($.tokenId).find.exists, found nothing
    Request 'Submit Credentials' failed for user 1: status.find.is(200), but actually found 401
    ```

* When deploying the `gatling` container to the cluster using Skaffold, this 
error indicates that the `gatling/k8s/key.json` is not present: 
    ```
    stderr: "Error: file sources: [key.json]: evalsymlink failure on '/Users/some.user/work/forgeops/docker/gatling/k8s/key.json' : lstat /Users/some.user/work/forgeops/docker/gatling/k8s/key.json: no such file or directory\n"
    ```

* If the `key.json` file is invalid, this error will appear in the Skaffold 
output:
    ```
    [perf-test] Exception in thread "main" com.google.cloud.storage.StorageException: 401 Unauthorized
    ```

* If the feeder is exhausted when you run a simulation, this error will appear. 
To fix it, increase your feeder size by increasing the `USER_POOL` value, or 
reduce the `DURATION` of your simulation:
    ```
    09:02:12.566 [ERROR] i.g.c.a.SingletonFeed - Feed failed: Feeder is now empty, stopping engine, please report.
    ```