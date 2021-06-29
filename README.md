# ForgeRock DevOps and Cloud Deployment

_Kubernetes deployment for the ForgeRock&reg; Identity Platform._

This repository provides Docker and Kustomize artifacts for deploying the 
ForgeRock Identity Platform on a Kubernetes cluster. 

This GitHub repository is a read-only mirror of
ForgeRock's [Bitbucket Server repository](https://stash.forgerock.org/projects/CLOUD/repos/forgeops). 
Users with ForgeRock BackStage accounts can make pull requests on our Bitbucket 
Server repository. ForgeRock does not accept pull requests on GitHub.

## Disclaimer

>This repository is provided on an “as is” basis, without warranty of any kind, 
to the fullest extent permitted by law. ForgeRock does not warrant or guarantee 
the individual success developers may have in implementing the code on their
development platforms or in production configurations. ForgeRock does not 
warrant, guarantee or make any representations regarding the use, results of use,
accuracy, timeliness or completeness of any data or information relating to these 
samples. ForgeRock disclaims all warranties, expressed or implied, and in 
particular, disclaims all warranties of merchantability, and warranties related
to the code, or any service or software related thereto. ForgeRock shall not be
liable for any direct, indirect or consequential damages or costs of any type 
arising out of any action taken by you or others related to the samples.
>
>See [Support from ForgeRock](https://backstage.forgerock.com/docs/forgeops/7.1/support.html)
for information about our support offering for this repository.

## What's New in 7.1 Release?

The highlights of the 7.1 release are:
* [New CDK technology preview](https://ea.forgerock.com/docs/forgeops/rn/highlights.html#r2021-05-12-new-cdk)
* [DS operator technology preview](https://ea.forgerock.com/docs/forgeops/rn/highlights.html#r2021-03-08-ds-operator)
* [New RCS Agent pod in the CDM](https://ea.forgerock.com/docs/forgeops/rn/highlights.html#r2021-03-08-rcs-agent)
* [Cloud Deployment Quickstart (CDQ)](https://ea.forgerock.com/docs/forgeops/rn/highlights.html#r2021-03-08-quickstart)
* [New Secret Agent operator](https://ea.forgerock.com/docs/forgeops/rn/highlights.html#r2020-10-28-secret-agent)
* [New cluster provisioning scripts](https://ea.forgerock.com/docs/forgeops/rn/highlights.html#r2020-10-28-cluster-provisioning)
* [Small, medium, and large CDM cluster sizing](https://ea.forgerock.com/docs/forgeops/rn/highlights.html#r2020-10-28-sml)

## How to Work With This Repository

See the instructions [here](https://ea.forgerock.com/docs/forgeops/forgeops.html) for information about how to work with a supported release.

_Before you start working with a release, make sure that you have the 
documentation that corresponds to that release._

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


## Getting Started

If you just want to observe the ForgeRock Identity Platform in action on a 
Kubernetes cluster, you can try out our [CDQ (Cloud Deployment 
Quickstart)](https://ea.forgerock.com/docs/forgeops/quickstart.html).
You can get the CDQ up and running quickly, but its capabilities are _very_ limited.   

For a full CDK deployment, you'll need to install the required third-party software, set
up a Kubernetes cluster, and install the ForgeRock Identity Platform. 

See the [CDK documentation](https://ea.forgerock.com/docs/forgeops/cdk/overview.html) 
for detailed information about all these tasks.

## Accessing Platform UIs and APIs

Details [here](https://ea.forgerock.com/docs/forgeops/cdk/access.html).

## Managing Configurations

ForgeRock uses the `config.sh` script to manage configurations. See [here](https://ea.forgerock.com/forgeops/cdk/develop/intro.html) for more information.

## New CDK

In version 7.1, the new `cdk` is introduced, using the new `cdk` you can manage
configurations and the entire deployment and management workflow. For more
information on the new `cdk`, see the 
[New Cloud Developer’s Kit Documentation](https://ea.forgerock.com/forgeops/previews/new-cdk/overview.html).

## Secrets

ForgeRock uses secrets generated by [Secret Agent Operator](https://ea.forgerock.com/forgeops/deployment/security/secret-agent.html).
 

## Troubleshooting Tips

See the [troubleshooting page](https://ea.forgerock.com/forgeops/troubleshooting/overview.html)
in the CDK documentation.

## Cleaning up

See [CDK Shutdown and Removal](https://ea.forgerock.com/forgeops/cdk/shutdown.html)
in the CDK documentation. 
