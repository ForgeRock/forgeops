# ForgeOps Developer Profile

_NOTE: This is work in progress. This is a preview of a developer-focused forgeops release._

The developer profile provides:

* **Reduced footprint deployment.**
  There is a single DS instance for the CTS and idrepo instead of multiple
  instances.

* **Phased deployment.** The developer profile is deployed in phases
  rather than by using a one-step _skaffold run_ deployment. The phased
  deployment lets you iterate on development without needing to reload users or
  recreate secrets.

## Deployment Steps

The `cdk` script verifies that the necessary prerequisites are installed.
If they are not present in your cluster, it will install them for you.
(ForgeRock staff using the `eng-shared` cluster: these have already been installed.)

1. Run the `./bin/cdk` script.
   You can specify things like _namespace_ and _FQDN_ for your deployment.
   Run `./bin/cdk --help` for more information about all the available parameters.

## Passwords

Run `./bin/cdk info` to obtain the administrator passwords and relevant URLs.

## Customizing the Deployment Profile Components

The default profile in `./bin/cdk` deploys the complete ForgeRock Identity
Platform. This profile is called quickstart.

If you wish to deploy a subset of apps, iterate over a specific app, or set
of apps, you can do so by deploying the platform components individually.

To deploy an individual component, specify the component name directly in the command line.
The example below demonstrates how to deploy the ForgeRock Identity Platform one component at a time.

```bash
./bin/cdk install base
./bin/cdk install ds-idrepo
./bin/cdk install am
./bin/cdk install amster
./bin/cdk install idm
./bin/cdk install admin-ui
./bin/cdk install end-user-ui
./bin/cdk install login-ui
./bin/cdk install rcs-agent
```

Alternatively, you can specify multiple components if no validation is required
in between deployments.

```bash
./bin/cdk install base ds-idrepo
./bin/cdk install am amster idm
./bin/cdk install admin-ui end-user-ui login-ui rcs-agent
```

**Note**: `base` must always be deployed first as it contains the platform dependencies.
`ds-idrepo` is also required by other components. It is recommended to deploy the platform
components in the order shown above.

This functionality gives the users total control of which components, and when, they want to
deploy in their target cluster. This is especially useful during debug sessions where
the user wants to quickly test different configurations for a single app without having to redeploy
the entire platform. For example:

```bash
# Install the full ForgeRock Identity Platform
./bin/cdk install --fqdn demo.iam.customer.com
# Delete only the IDM-related resources
./bin/cdk delete idm
# Patch the platform-config configmap with a different setting
kubectl patch cm platform-config --type=json -p='[{"op":"replace", "path": "/data/RCS_AGENT_ENABLED", "value": "true"}]'
# Deploy IDM once again
./bin/cdk install idm
# When done, uninstall the developer profile
./bin/cdk delete
```

Let's say users want to iterate over several Docker images as they test different settings for the admin-ui pod:

```bash
# Install the full ForgeRock Identity Platform
./bin/cdk install --fqdn demo.iam.customer.com
# Update the docker image of the admin-ui deployment
kubectl set image deployment admin-ui admin-ui=gcr.io/forgeops-public/admin-ui:my-custom-tag1
# After some testing, the user decides to test another image with some other changes
kubectl set image deployment admin-ui admin-ui=gcr.io/forgeops-public/admin-ui:my-custom-tag2
# When done, uninstall the developer profile
./bin/cdk delete
```

### Component Bundles

As mentioned above, the `./bin/cdk` script provides complete control of the components the user wants to deploy.
Users can achieve complete control by deploying individual components. However, it is understandable
users may want a simpler deployment while still maintaining certain level of customization.

We provide 5 main _bundles_ of components:
| Bundle | Included Components |
|-|-|
| `quickstart`| Contains all components. This is the default bundle |
| `base`      | platform-config, dev-utils<br>git-sever<br>secrets<br>ingress |
| `ds`        | ds-cts, ds-idrepo |
| `apps`      | am, amster, idm, rcs-agent|
| `ui`        | admin-ui end-user-ui login-ui |

Users can chose to install components as part of a bundle, individually or a combination of both.
To deploy a bundle, specify the name of the bundle directly in the command line.

For example, let's say the user wants to deploy AM, IDM, idrepo and CTS. In order to save resources and deployment time,
the developer profile provides a single DS instance for the CTS and idrepo. Users can easily change this configuration:

```bash
# Deploy the base bundle. This bundle is always required.
# Note: The default FQDN is set to default.iam.example.com. You can use "-a $FQDN" to change it while deploying "base"
./bin/cdk install base --fqdn myownfqdn.mydomain.com
# Change the configmap directing AM to use ds-cts as CTS server
kubectl patch cm platform-config --type=json -p='[{"op":"replace", "path": "/data/AM_STORES_CTS_SERVERS", "value": "ds-cts-0.ds-cts:1636"}]'
# Deploy ds-idrepo and ds-cts
./bin/cdk install ds-idrepo ds-cts
# Scale the ds-cts statefulset. By default, the developer profile has replicas=0 for ds-cts
kubectl scale statefulset ds-cts --replicas=1
# Deploy the apps bundle
./bin/cdk install --components apps
# When done, uninstall the developer profile
./bin/cdk delete
```

### Stable Images and Manifests

By default, the `cdk` script deploys platform components based on local manifests and uses nightly docker images.
This mode is known as [development mode](#development-mode). While that mode is sufficient for the majority
of `cdk` use cases, there are instances in which stable images and/or manifests are preferred. For these cases,
the user just need to specify the `--stable` flag when installing a component. The `cdk` script will install the latest stable
manifest and images of the given [component](#customizing-the-deployment-profile-components) or [bundle](#component-bundles).

By default, the `--stable` flag installs the _latest_ manifest and docker images. The user can use the `--tag` to specify
a different forgeops tag if required.

```bash
# Install the latest stable ForgeRock Identity Platform
./bin/cdk install --fqdn demo.iam.customer.com --stable
# When done, uninstall the developer profile
./bin/cdk delete
```

### Development mode

Development mode allows the user to deploy platform components using local manifests. In this mode, the script gathers
the manifest of the specified component or bundle from your local _kustomize_ folder rather
than using the latest public release. In addition, the docker images are set to the latest _nightly_ image of each component.
This is the default mode used by the `cdk` script.

For example, let's assume the user wants to run the platform using the latest stable release. However, the user wants
nightly images for all UI components and a special image tag for the admin-ui pod:

```bash
# Install the latest stable ForgeRock Identity Platform
./bin/cdk install --fqdn demo.iam.customer.com --stable
# Install the ui bundle using local manifests and latest nightly image
./cdk install ui
# Update the docker image of the admin-ui deployment only
kubectl set image deployment admin-ui admin-ui=gcr.io/forgeops-public/admin-ui:my-custom-tag1
# When done, uninstall the developer profile
./bin/cdk delete
```

## Exporting changes


1. Export the config using `./bin/config.sh`

    ```bash
    # Extract the configurations from the git-server and copy them to your local "./docker" folder
    ./config.sh export
    # Copy the configs from ./docker/ into ./config
    ./config.sh save
    ```

## Deleting the ForgeRock Identity Platform Deployment

You can run `./bin/cdk delete` to delete the deployment. This command will delete all components
of the developer profile regardless of the bundles or component.
Note that all PVCs (including git and ds persistence) are also removed.

If you just wish to scale down the pods, you can do

```bash
kubectl scale deployment --all --replicas=0
kubectl scale statefulset --all --replicas=0
```

And to resume:

```bash
kubectl scale deployment --all --replicas=1
kubectl scale statefulset --all --replicas=1
```
