# ForgeRock DevOps and Cloud Deployment

Kubernetes deployment for the ForgeRock platform. Branches:

* Recommended for production: release/6.5.2 branch
* Technology preview: skaffold-6.5 branch.
* Under development master branch

Note: The charts in the helm/ directory are deprecated and will be removed in the future. The Helm charts
are being replaced with Kustomize.

This GitHub repository is a read-only mirror of
ForgeRock's [Bitbucket Server repository](https://stash.forgerock.org/projects/CLOUD/repos/forgeops). Users
with BackStage accounts can make pull requests on our Bitbucket Server repository. ForgeRock does not
accept pull requests on GitHub.

## Disclaimer

>These samples are provided on an “as is” basis, without warranty of any kind, to the fullest extent
permitted by law. ForgeRock does not warrant or guarantee the individual success developers
may have in implementing the code on their development platforms or in
production configurations. ForgeRock does not warrant, guarantee or make any representations
regarding the use, results of use, accuracy, timeliness or completeness of any data or
information relating to these samples. ForgeRock disclaims all warranties, expressed or implied, and
in particular, disclaims all warranties of merchantability, and warranties related to the code, or any
service or software related thereto. ForgeRock shall not be liable for any direct, indirect or
consequential damages or costs of any type arising out of any action taken by you or others related
to the samples.


## Documentation

The draft ForgeRock DevOps Developer's Guides
( [minikube](https://ea.forgerock.com/docs/platform/devops-guide-minikube)|
[shared cluster](https://ea.forgerock.com/docs/platform/devops-guide-cloud)]
tracks the master branch, including information on the newer Kustommize/ Skaffold workflow. If you are
just getting started this is the recommended path.

The documentation for the current release can be found on
[backstage](https://backstage.forgerock.com/docs/platform).


## Skaffold preview branch

The branch `skaffold-6.5` is a preview of the upcoming 7.x workflow that simplifies deployment
by bundling the product configuration into the docker image for deployment. This workflow speeds iterative
development and greatly simplifies the Kubernetes runtime manifests. It eliminates the need for Git init containers
and the complexity around configuring different Git repositories and branches in the helm charts.

The new workflow combines the previously
independent `forgeops` and `forgeops-init` repositories into a single Git repository that holds configuration and Kubernetes
manifests.  Documentation for this workflow is in progress. Please
 see the [early access documentation](https://ea.forgerock.com/docs/platform/devops-guide-minikube/#devops-guide-minikube).

This preview branch enables the use of supported ForgeRock binaries in your
 deployment.

 **Adopting this workflow now is recommended as it will ease transition to the 7.x platform.**

## Configuration

The provided configuration
is a basic installation that can be further extended by developers to meet their requirements. Developers should fork
this repository in Git, and modify the various configuration files.

The configuration provides the following features:

* Deployments for ForgeRock AM, IDM, DS and IG. IG is not deployed by default.
* AM and IDM are integrated, and share a common repository for users. The directory server instance
(ds-idrepo) is used as the user store for both products, and as the managed repository for IDM objects. A
separate postgres SQL database is *NOT* required.
* AM protects the IDM administration and end user UI pages.
* AM is configured with a single root realm
* A number of OIDC clients are configured for the AM/IDM integration and the smoke tests.
** Note the `idm-provisioning`, `idmAdminClient` and the `endUserUI` client configurations are required for the
  integration of IDM and AM.
* Directory service instances are configured for:
 - The shared AM/IDM repo (ds-idrepo)
 - The AM dynamic runtime data store for polices and agents (currently the ds-idrepo is also used for this purpose).
 - The Access Manager Core Token Service (ds-cts).
* A very simple landing page (/web)
* A Python test harness. This test harness (forgeops-test) exercises the basic deployment and
can be modified to include additional tests. 

When deployed, the following URLs are available (The domain name below is the default
for minikube and can be modified for your environment)

* https://default.iam.example.com/web - web landing page
* https://default.iam.example.com/am  - Access manager admin  (amadmin/password)
* https://default.iam.example.com/admin - IDM admin (login with amadmin credentials)
* https://default.iam.example.com/enduser  - End User UI page
* https://default.iam.example.com/ig  - Identity Gateway (Optional)

The various configuration files are located in the `docker` and bundled with their respective
products (amster, idm, ig, am).

## Managing Configurations

The `bin/config.sh` utility is used to initialize a configuration and to synchronize files to and from a running instance.

A number of configuration profiles and product versions are under the [config](config/) folder. The format
of the folder structure is `config/$VERSION/$PROFILE` - where VERSION is the ForgeRock product version (6.5,7.0) and
PROFILE is the configuration profile that makes up the deployment.

The `config/` directory is under version control. The target `docker/{product}/conf` directories are not versioned (via
.gitignore). The workflow is that initial configuration is copied from the `config/` directory to the target `docker/`
folder.  During development, configuration is exported back out of the running products to the `docker` folder, and
then optionally copied back to the `config/` folder where it can be committed to version control.


The `bin/config.sh` utility takes the following arguments:

* `--profile <profile>` : Specifies the profile. The default is the `cdk`. The environment variable $CDK_PROFILE can
  override the default.
* `--component <am|idm|amster|ig|all>`: specifies the component to configure. This defaults to `all` components.
* `--version <6.5|7.0>`: The platform version (default 7.0). The environment variable `CDK_VERSION` can override this.

To setup your environment for the CDK, use the `init`command:

```bash
bin/config.sh init
```

The above copies the configuration profile under the Git-managed `config/7.0/cdk` directory to the  `docker/7.0` folder

**Keep in mind that the configuration files under the `docker/$version/$product/$config` folder are not maintained in Git.**.  They
are considered temporary build-time assets.

You can select alternate configuration profiles, or initialize specific components:

```bash
# Initializes the "test" configuration profile for IDM 6.5
bin/config.sh --profile test --component idm --version 6.5 init
# Initialize the "test" configuration for all ForgeRock components for the default 7.0 version
bin/config.sh --profile test
#
```


The `export` command is used to export configuration from a running instance (e.g., IDM) back to the `docker` folder. Note that not all
components support export functionality (currently just IDM and amster).

```bash
# Export all configurations to the docker folder
bin/config.sh export
# Export the IDM configuration to the docker folder
bin/config.sh --component idm export
```

The `save` command copies the contents of the Docker configuration *back* to the config/ folder where it can be versioned in Git.

```bash
# Save the docker/ configuration for all ForgeRock components back to the config/ folder
bin/config.sh save
# Save just the IDM configuration to the test configuration profile
bin/config.sh --component idm --profile test save
```

The `diff` command runs GNU `diff` to show the difference between the `docker/` component folder and the Git configuration:

```bash
bin/config.sh --component idm --profile cdk diff
```


Finally, the `sync` command combines the `export` and `save` functions into a single command:

```bash
# Export from all running products to the docker folder, then save the results to the git folder:
bin/config.sh sync
# Export and save just idm for the test config
bin/config.sh --component idm --profile test sync
```

The `git status` command will show you any changes made to the `config` folder. You can decide whether to commit or discard those changes.

To discard, you can run `git restore config`. As a convenience, the command `bin/config.sh restore`  runs this git command for you.

A sample session using the CDK is as follows:

```bash
bin/config.sh init
# run cdk configs
skaffold dev
# Make changes in the IDM UI. Then:
bin/config.sh sync
# See what changed
git status
# Commmit, or discard your changes
bin/config.sh restore
```

To add a new configuration, copy the contents of an existing configuration to your new folder:

```bash
cd config/7.0
cp -r cdk my_great_config
git add my_great_config
```

## Changing DS profile

To deploy the latest DS version with older setup-profile versions, add the following buildArgs to the DS image:

```  
build:
  artifacts:
  - image: ds-cts
    context: docker/7.0/ds/cts
    docker:
      buildArgs:
        profile_version: "6.5"
  - image: ds-idrepo
    context: docker/7.0/ds/idrepo
    docker:
      buildArgs:
        profile_version: "6.5"
```

On default, the latest setup-profile version is always deployed.

## Secrets 

CDK and CDM deployments use a default set of secrets. Instead of using the default secrets, you can
randomly generate secrets for the ForgeRock Identity Platform using the forgeops-secrets tool. 
For more information about randomly generating secrets, see the  
[forgeops-secrets README](docker/forgeops-secrets/forgeops-secrets-image/README.md) 


## Troubleshooting Tips

Refer to the toubleshooting chapter in the [DevOps Guide](https://backstage.forgerock.com/docs/platform/6/devops-guide/#chap-devops-troubleshoot).

Troubleshooting suggestions:

* The script `bin/debug-log.sh` will generate an HTML file with log output. Useful for troubleshooting.
* Simplify. Deploy a single product at a time (for example, ds), and make sure it is working correctly before deploying the next product.
* Describe a failing pod using `kubectl get pods; kubectl describe pod pod-xxx`
    1. Look at the event log for failures. For example, the image can't be pulled.
    2. Examine any init containers. Did each init container complete with a zero (success) exit code? If not, examine the logs from that failed init container using `kubectl logs pod-xxx -c init-container-name`
    3. Did the main container enter a crashloop? Retrieve the logs using `kubectl logs pod-xxx`.
    4. Did a docker image fail to be pulled?  Check for the correct docker image name and tag. If you are using a private registry, verify your image pull secret is correct.
    5. You can use `kubectl logs -p pod-xxx` to examine the logs of previous (exited) pods.
* If the pods are coming up successfully, but you can't reach the service, you likely have ingress issues:
    1. Use `kubectl describe ing` and `kubectl get ing ingress-name -o yaml` to view the ingress object.
    2. Describe the service using `kubectl get svc; kubectl describe svc xxx`.  Does the service have an `Endpoint:` binding? If the service endpoint binding is not present, it means the service did not match any running pods.
* Determine if your cluster is having issues (not enough memory, failing nodes). Watch for pods killed with OOM (Out of Memory). Commands to check:
    1. `kubectl describe node`
    2. `kubectl get events -w`
* Most images provide the ability to exec into the pod using bash, and examine processes and logs.  Use `kubectl exec pod-name -it bash`.
* If `skaffold dev` fails because it does not have permissions to push a docker image it may be trying
to push to the docker hub (the reported image name will be something like `docker.io/am`).
  When running on minikube, Skaffold assume that a push is not required as it can `docker build` direct to
  the docker machine. If it is attempting to push the docker hub it is because Skaffold thinks
  it is *not* running on minikube. Make sure your
   minikube context is named `minikube`. An alternate solution
   is to modify the docker build in `skaffold.yaml` and set `local.push` to false. See the
   [skaffold.dev](https://skaffold.dev) documentation.


## Kustomizing the deployment

Create a copy of one of the environments. Example:

```
cd kustomize/env
cp -r dev test-gke
```

* Using a text editor, or sed, change all the occurences of the FQDN to your desired target FQDN.
  Example, change `default.iam.forgeops.com` to `test.iam.forgeops.com`
* Update the DOMAIN in platform-config.yaml to the proper cookie domain for AM.
* Update kustomization.yaml with your desired target namespace (example: `test`). The namespace must be the same as the FQDN prefix.
* Copy skaffold.yaml to skaffold-dev.yaml. This file is in .gitignore so it does not get checked in or overlayed on a Git checkout.
* In skaffold-dev.yaml, edit the `path` for kustomize to point to your new environment folder (example: `kustomize/env/test-gke`).
* Run your new configuration:  `skaffold dev -f skaffold-dev.yaml [--default-repo gcr.io/your-default-repo]`
* Warning: The AM install and config utility parameterizes the FQDN - but you may need to fix up other configurations in
IDM, IG, end user UI, etc. This is a work in progress.

## Cleaning up

`skaffold delete` or `skaffold delete -f skaffold-dev.yaml`

If you want to delete the persistent volumes for the directory:

`kubectl delete pvc --all`

## Continuous Deployment

The file `cloudbuild.yaml` is a sample [Google Cloud Builder](https://cloud.google.com/cloud-build/) project
that performs a continuous deployment to a running GKE cluster. Until AM file based configuration supports upgrade,
the deployment is done fresh each time.

The deployment is triggered from a `git commit` to [forgeops](https://github.com/ForgeRock/forgeops). See the
documentation on [automated build triggers](https://cloud.google.com/cloud-build/docs/running-builds/automate-builds) for more information.  You can also manually submit a build using:

```bash
cd forgeops
gcloud builds submit
```

Track the build progress in the [GCP console](https://console.cloud.google.com/cloud-build/builds).

Once deployed, the following URLs are available:

* [Smoke test report](https://smoke.iam.forgeops.com/tests/latest.html)
* [Access Manager](https://smoke.iam.forgeops.com/am/XUI/#login/)
* [IDM admin console](https://smoke.iam.forgeops.com/admin/#dashboard/0)
* [End user UI](https://smoke.iam.forgeops.com/enduser/#/dashboard)

