# ForgeRock DevOps and Cloud Deployment

_Kubernetes deployment for the ForgeRock&reg; Identity Platform._

This repository provides Docker and Kustomize artifacts for deploying the 
ForgeRock Identity Platform on a Kubernetes cluster. 

This GitHub repository is a read-only mirror of
ForgeRock's [Bitbucket Server repository](https://stash.forgerock.org/projects/CLOUD/repos/forgeops). Users
with ForgeRock BackStage accounts can make pull requests on our Bitbucket Server repository. ForgeRock does not
accept pull requests on GitHub.

## Disclaimer

>This repository is provided on an “as is” basis, without warranty of any kind, to the fullest extent
permitted by law. ForgeRock does not warrant or guarantee the individual success developers
may have in implementing the code on their development platforms or in
production configurations. ForgeRock does not warrant, guarantee or make any representations
regarding the use, results of use, accuracy, timeliness or completeness of any data or
information relating to these samples. ForgeRock disclaims all warranties, expressed or implied, and
in particular, disclaims all warranties of merchantability, and warranties related to the code, or any
service or software related thereto. ForgeRock shall not be liable for any direct, indirect or
consequential damages or costs of any type arising out of any action taken by you or others related
to the samples.
>
>See [Support from ForgeRock](https://backstage.forgerock.com/docs/forgeops/7/getting-support.html)
for information about our support offering for this repository.

## How to Work With This Repository

You can choose to: 

* Check out a release that's officially supported by ForgeRock. See the 
instructions [here](https://backstage.forgerock.com/docs/forgeops/7/about-forgeops.html)
for information about how to work with a supported release. Documentation
[here](https://backstage.forgerock.com/docs/forgeops/7/index.html).

* Check out an interim pre-release&mdash;a release that's newer than the officially
supported release, but is not supported by ForgeRock. Get interim pre-releases 
[here](https://github.com/ForgeRock/forgeops/releases). Documentation for an interim
pre-release is provided as a `.zip` file asset in the release.

* Check out the `master` branch to work with the latest code. Documentation 
[here](https://ea.forgerock.com/docs/forgeops).

_Before you start working with a release, make sure that you have the documentation
that corresponds to that release._

## ForgeRock Identity Platform Configuration

The provided configuration, which we call the Cloud Developer's Kit (CDK),
is a basic installation that can be further extended by developers to meet their requirements. 
The configuration provides the following features:

* Deployments for ForgeRock AM, IDM, DS and IG. IG is not deployed by default, but is available optionally.
* AM configured with a single root realm.
* A number of OIDC clients configured for AM/IDM integration and for smoke tests.
Note that the `idm-provisioning`, `idm-admin-ui` and the `end-user-ui` client configurations are required for the
integration of IDM and AM.
* Directory service instances configured for:
   * The shared AM/IDM repo (ds-idrepo).
   * The AM dynamic runtime data store for polices and agents. Currently, the ds-idrepo is used.
   * The Access Manager Core Token Service (ds-cts).
* A Gatling test harness, which exercises the basic deployment and can be modified to include additional tests.

The 7.0 deployment provide the following additional enhancements:

* AM and IDM are integrated, and share a common repository for users. The directory server instance
(ds-idrepo) is used as the user store for both products, and as the managed repository for IDM objects. A
separate postgres SQL database is *NOT* required.
* AM protects the IDM administration and end user UI pages.
* The /openidm REST endpoint is protected using OAuth 2.0.

## Getting Started

You'll need to install some third-party software, set up a Kubernetes cluster, and
install the ForgeRock Identity Platform. 

See the [CDK documentation](https://backstage.forgerock.com/docs/forgeops/7/index-cdk.html) 
for detailed information about all these tasks.

## Accessing Platform UIs and APIs

Details [here](https://backstage.forgerock.com/docs/forgeops/7/devops-usage-access.html).

## Managing Configurations

Details [here](https://backstage.forgerock.com/docs/forgeops/7/devops-develop.html).

Additional information about `config.sh` script options:

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

Editing AM configuration in the AM UI will rewrite the configuration files in the AM pod.  Any placeholders(commons expressions) will be replaced with the actual value.  The export function triggers a job to reinstate all placeholders into the configuration files.

```bash
# Export all configurations to the docker folder
bin/config.sh export
# Export the IDM configuration to the docker folder
bin/config.sh --component idm export
```

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

## Secrets

Interim pre-releases and the `master` branch use secrets generated and managed 
by the [secret-agent operator](https://github.com/ForgeRock/secret-agent/blob/master/README.md).

The release that's officially supported by ForgeRock uses secrets generated by the 
[secrets generator job](https://backstage.forgerock.com/docs/forgeops/7/deployment-security.html).
This method of generating secrets will be deprecated in the next officially
supported release.

## Troubleshooting Tips

See the [troubleshooting page](https://backstage.forgerock.com/docs/forgeops/7/devops-troubleshoot.html)
in the CDK documentation.

## Cleaning up

See [CDK Shutdown and Removal](https://backstage.forgerock.com/docs/forgeops/7/devops-shutdown.html)
in the CDK documentation. 
