# ForgeRock DevOps and Cloud Deployment

Kubernetes deployment for the ForgeRock platform.

This repository provides Docker and Kustomize artifacts for deploying both 6.5 and 7.0 (under development) products
to a Kubernetes cluster. If you are starting out, using the `master` branch is recommended.

## Quick Start

```bash
# Initialize the configuration profile. Important!!!
bin/config.sh -v 7.0 init
# Add the ingress IP to your /etc/hosts. Create an entry for default.iam.example.com
minikube ip
# run skaffold in dev mode
skaffold dev
# Open https://default.iam.example.com/am  in your browser
```

## Documentation

Please see the (DevOps)[https://backstage.forgerock.com/docs/forgeops/6.5] documentation.

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

## Quickstart

If you have an existing cluster and it's configured to work with [kaniko](https://github.com/GoogleContainerTools/kaniko#running-kaniko-in-a-kubernetes-cluster) then the forgeops-toolbox allows building and deploy the ForgeRock Identity Platform from within kubernetes. This minimizes the a developers local environment dependencies to be h  `bash`, `kubectl`, and `kustomize`.

Refer to `kustomize/base/toolbox/README.md` for more info on getting started using the `foregops-toolbox`.

## Configuration

The provided configuration
is a basic installation that can be further extended by developers to meet their requirements. Developers should fork
this repository in Git, clone the fork, and modify the various configuration files.

The configuration provides the following features:

* Deployments for ForgeRock AM, IDM, DS and IG. IG is available but not deployed by default.
* AM is configured with a single root realm
* A number of OIDC clients are configured for the AM/IDM integration and the smoke tests.
** Note the `idm-provisioning`, `idm-admin-ui` and the `end-user-ui` client configurations are required for the
  integration of IDM and AM.
* Directory service instances are configured for:
 - The shared AM/IDM repo (ds-idrepo)
 - The AM dynamic runtime data store for polices and agents (currently the ds-idrepo is also used for this purpose).
 - The Access Manager Core Token Service (ds-cts).
* A very simple landing page (/web)
* A Python test harness. This test harness (forgeops-test) exercises the basic deployment and
can be modified to include additional tests.

The 7.0 deployment provide the following additional enhancements:

* AM and IDM are integrated, and share a common repository for users. The directory server instance
(ds-idrepo) is used as the user store for both products, and as the managed repository for IDM objects. A
separate postgres SQL database is *NOT* required.
* AM protects the IDM administration and end user UI pages.
* The /openidm REST endpoint is protected using OAuth 2.0

## Deployed URLs

When deployed, the following URLs are available (The domain name below is the default
for minikube and can be modified for your environment)

* https://default.iam.example.com/am  - Access manager admin  (amadmin/password)
* https://default.iam.example.com/admin - IDM admin (login with amadmin credentials on 7.0)
* https://default.iam.example.com/platform  - 7.0 Admin landing page (under development)
* https://default.iam.example.com/ig  - Identity Gateway (Optional)

## Managing Configurations

The `bin/config.sh` utility is used to initialize a configuration and to synchronize files to and from a running instance.

A number of configuration profiles and product versions are under the [config](config/) folder. The format
of the folder structure is `config/$VERSION/$PROFILE` - where VERSION is the ForgeRock product version (6.5,7.0) and
PROFILE is the configuration profile that makes up the deployment.

The `config/` folder is under version control. The target `docker/{version}/{product}/conf` folders are NOT versioned (via
.gitignore). Configuration is copied from the git versioned `/conf` folder to the non versioned docker folder. Consider the
configuration under docker/ to be a staging area.  During development, configuration can be exported out of the running
product (e.g. AM or IDM) to the staging area, and if
desired, copied back out to the git versioned `config/` folder where it can be committed to version control.  

**`NOTE`** This functionality doesn't apply to the AM exported files 
due to the complexity merging in new and updated files.

The `bin/config.sh` script automates the copy / export process. The `init` command is used to initialize
(copy from /conf/ to the staging area under docker).

`config.sh` takes the following arguments:

* `--profile <profile>` : Specifies the profile. The default is the `cdk`. The environment variable $CDK_PROFILE can
  override the default.
* `--component <am|idm|amster|ig|all>`: specifies the component to configure. This defaults to `all` components.
* `--version <6.5|7.0>`: The platform version (default 7.0). The environment variable `CDK_VERSION` can override this.

To setup your environment for the CDK, use the `init` command:

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

**EXPORT**  
The `export` command is used to export configuration from a running instance (e.g. IDM) back to the `docker` staging folder. Note that currently IDM, AM, and Amster support export functionality.

**IDM export**  
Configuration is exported to `docker/$version/idm/conf` and is a full copy of the configuration including any changes.  

**Amster export**  
Amster only runs as a Kubernetes job so there is no running deployment.  The export command kicks of a new Amster job to export OAuth2Clients and ig-agent config from AM.  
Configuration is exported to `docker/$version/amster/config`.

**AM export**  
AM configuration export works differently. Due to the large number of config files in file based configuration, we don't want to export all files. So the export identifies only the updated configuration and exports any updated files.  
These updated files are exported to `docker/$version/am/config`.

```bash
# Export all configurations to the docker folder
bin/config.sh export
# Export the IDM configuration to the docker folder
bin/config.sh --component idm export
```

**`NOTE`** All configuration except the commons placeholders are exported.  These will need to be restored where necessary. 

**SAVE**  
The `save` command copies the contents of the Docker configuration *back* to the `config/` folder where it can be versioned in Git.  

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

## Changing the DS profile to support older ForgeRock releases.

To deploy the latest DS 7.0 directory server with profiles for previous (6.5) products , add the following buildArgs to the DS image:

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

By default, the latest setup-profile version (7.0) is deployed.

## Secrets

CDK and CDM deployments use a default set of secrets. Instead of using the default secrets, you can
randomly generate secrets for the ForgeRock Identity Platform using the forgeops-secrets tool.
For more information about randomly generating secrets, see the
[forgeops-secrets README](docker/forgeops-secrets/forgeops-secrets-image/README.md)


## Development SSL Certificates

If you are on minikube and would like to use a certificate that is accepted by your browser,  we suggest using
the [mkcert](https://github.com/FiloSottile/mkcert) program.  Nginx will look for a TLS secret in the namespace
called `sslcert` (this is defined by the ingress definition). Here is a sample of how to create and install
a test certificate:

```bash
mkcert "*.iam.example.com"
kubectl create secret tls sslcert --cert=_wildcard.iam.example.com.pem --key=_wildcard.iam.example.com-key.pem
```

## Troubleshooting Tips

Refer to the troubleshooting chapter in the [DevOps Guide](https://ea.forgerock.com/docs/forgeops/devops-guide-cloud/#chap-devops-troubleshoot).

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
cd kustomize/overlays/6.5
cp -r medium my-new-overlay
```

* Using a text editor, or sed, change all the occurences of the FQDN to your desired target FQDN.
  Example, change `default.iam.forgeops.com` to `test.iam.forgeops.com`
* Update the DOMAIN to the proper cookie domain for AM.
* Update kustomization.yaml with your desired target namespace (example: `test`). The namespace must be the same as the FQDN prefix.
* Copy skaffold.yaml to skaffold-dev.yaml. This file is in .gitignore so it does not get checked in or overlayed on a Git checkout.
* In skaffold-dev.yaml, edit the `path` for kustomize to point to your new environment folder (example: `kustomize/env/test-gke`).
* Run your new configuration:  `skaffold dev -f skaffold-dev.yaml [--default-repo gcr.io/your-default-repo]`
* Warning: The AM install and config utility parameterizes the FQDN - but you may need to fix up other configurations in
IDM, IG, end user UI, etc. This is a work in progress.

The experimental script `bin/init-platform.sh` can be used to create a new Skaffold and Kustomize profile for a custom domain.
Refer to the help for that script.

## Cleaning up

`skaffold delete` or `skaffold delete -f skaffold-dev.yaml`

If you want to delete the persistent volumes for the directory:

`kubectl delete pvc --all`

The script `bin/clean.sh` will perform the above as well as delete any generated secrets.

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
