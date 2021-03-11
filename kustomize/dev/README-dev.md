# ForgeOps Developer Profile

_NOTE: This is work in progress. This is a preview of a developer-focused forgeops release._

The developer profile provides:

* **Reduced footprint deployment.**
  There is a single DS instance for the CTS and idrepo instead of multiple
  instances.
* **Developer Git server.**
  IDM and AM configurations are saved to an "emptyDir" volume, and then pushed
  to a Git server pod running in the developer's namespace. Any changes the
  developer makes in the AM and IDM UIs are be saved to Git.
* **Phased deployment.** The developer profile is deployed in phases
  rather than by using a one-step _skaffold run_ deployment. The phased
  deployment lets you iterate on development without needing to reload users or
  recreate secrets.

## Deployment Steps

The `quickstart.sh` script verifies that the necessary prerequisites are installed.
If they are not present in your cluster, it will install them for you.
(ForgeRock staff using the `eng-shared` cluster: these have already been installed.)

1. Run the `./bin/quickstart.sh` script.
   You can specify things like _namespace_ and _FQDN_ for your deployment.
   See `./bin/quickstart.sh -h` for more information about all the available parameters.

## Passwords

Run `./bin/quickstart.sh -p` to obtain passwords for the AM and IDM UIs.

## Customizing the Deployment Profile Components

The default profile in `./bin/quickstart.sh` deploys the complete ForgeRock Identity
Platform. If you wish to deploy a subset of apps, iterate over a specific app, or set
of apps, you can do so by deploying the platform components individually.

To deploy an individual component, specify the component name using the `-c` arg.
The example below demonstrates how to deploy the ForgeRock Identity Platform one component at a time.

```bash
./bin/quickstart.sh -c base
./bin/quickstart.sh -c ds-idrepo
./bin/quickstart.sh -c am
./bin/quickstart.sh -c amster
./bin/quickstart.sh -c idm
./bin/quickstart.sh -c admin-ui
./bin/quickstart.sh -c end-user-ui
./bin/quickstart.sh -c login-ui
./bin/quickstart.sh -c rcs-agent
```

**Note**: `base` must always be deployed first as it contains the platform dependencies.
`ds-idrepo` is also required by other components. In general, it is recommended to deploy the platform
components in the order shown above.

This functionality gives the users total control of which apps, and when, they want to
deploy in their target cluster. This is especially useful during debug sessions where
the user wants to quickly test different configurations for a single app without having to redeploy
the entire platform. For example:

```bash
# Install the full ForgeRock Identity Platform
./bin/quickstart.sh -a demo.iam.customer.com
# Delete only the IDM related resources
./bin/quickstart.sh -c idm -u
# Patch the platform-config configmap with a different setting
kubectl patch cm platform-config --type=json -p='[{"op":"replace", "path": "/data/RCS_AGENT_ENABLED", "value": "true"}]'
# Deploy IDM once again
./bin/quickstart.sh -c idm
# When done, uninstall the developer profile
./bin/quickstart.sh -u
```

Let's say users want to iterate over several docker images as they test different settings for the admin-ui pod:

```bash
# Install the full ForgeRock Identity Platform
./bin/quickstart.sh -a demo.iam.customer.com
# Update the docker image of the admin-ui deployment
kubectl set image deployment admin-ui admin-ui=gcr.io/forgeops-public/admin-ui:my-custom-tag1
# After some testing, the user decides to test another image with some other changes
kubectl set image deployment admin-ui admin-ui=gcr.io/forgeops-public/admin-ui:my-custom-tag2
# When done, uninstall the developer profile
./bin/quickstart.sh -u
```

### Component Bundles

As we mentioned above, the `./bin/quickstart.sh` script provides complete control of the components the user wants to deploy.
Users can achieve complete control by deploying individual components. However, it is understandable
users may want a simpler deployment while still maintaining certain level of customization.

We provide 4 main _bundles_ of components:
| Bundle | Included Components |
|-|-|
| `base`| platform-config, dev-utils<br>git-sever<br>secrets<br>ingress |
| `ds`  | ds-cts, ds-idrepo |
| `apps`| am, amster, idm, rcs-agent|
| `ui`  | admin-ui end-user-ui login-ui |

Users can chose to install components as part of a bundle, individually or a combination of both.
To deploy a bundle, specify the name of the bundle by using the `-c` argument.

For example, let's say the user wants to deploy AM, IDM, idrepo and CTS. In order to save resources and deployment time,
the developer profile provides a single DS instance for the CTS and idrepo. Users can easily change this configuration:

```bash
# Deploy the base bundle. This bundle is always required. 
# Note: The default FQDN is set to default.iam.example.com. You can use "-a $FQDN" to change it while deploying "base"
./bin/quickstart.sh -c base -a myownfqdn.mydomain.com
# Change the configmap directing AM to use ds-cts as CTS server
kubectl patch cm platform-config --type=json -p='[{"op":"replace", "path": "/data/AM_STORES_CTS_SERVERS", "value": "ds-cts-0.ds-cts:1389"}]'
# Deploy ds
./bin/quickstart.sh -c ds
# Scale the ds-cts statefulset. By default, the developer profile has replicas=0 for ds-cts
kubectl scale statefulset ds-cts --replicas=1
# Deploy the apps bundle
./bin/quickstart.sh -c apps
# When done, uninstall the developer profile
./bin/quickstart.sh -u
```

### Local mode (Development mode)

This mode allows the user to deploy platform components using local manifests. In this mode, the script gathers
the manifest of the specified component or bundle from your local _kustomize_ folder rather
than using the latest public release. In addition, the docker images are set to the latest _nightly_ image of each component.
To run the script in this mode, run `./quickstart.bin -l [flags]`.

For example, let's assume the user wants to run the platform using the latest stable release. However, the user wants
nightly images for all UI components and a special image tag for the admin-ui pod:

```bash
# Install the full ForgeRock Identity Platform
./bin/quickstart.sh -a demo.iam.customer.com
# Install the ui bundle using local manifests and latest nightly image
./quickstart.sh -c ui -l
# Update the docker image of the admin-ui deployment only
kubectl set image deployment admin-ui admin-ui=gcr.io/forgeops-public/admin-ui:my-custom-tag1
# When done, uninstall the developer profile
./bin/quickstart.sh -u
```

## Pulling Files From The Git Server

The _git-server_ pod contains the updates that you have made to the AM and IDM configurations.
This Git server is deployed by default as part of the developer profile. It is also present in the "base" bundle.

There are two ways to extract the configs from the git server:

1. Clone the repo:

    ```bash
    kubectl port-forward deployment/git-server 8080:8080

    # In a different shell
    git clone http://git:forgerock@localhost:8080/fr-config.git
    ```

    The AM updates are in the `am` branch, and the IDM updates are in the `idm` branch.
    It is worth noting that the `am` configs are stored "raw" in the repo.
    The user is expected to run the `am-config-upgrader` to replace the necessary placeholders.
1. Export the config using `./bin/config.sh`

    This is the most streamlined approach available to export configs. The script copies the data and runs
    the `am-config-upgrader`. It then copies the configs to your local environment.

    ```bash
    # Extract the configurations from the git-server and copy them to your local "./docker" folder
    ./config.sh export-dev
    # Copy the configs from ./docker/ into ./config
    ./config.sh save
    ```

## Deleting the ForgeRock Identity Platform Deployment

You can run `./bin/quickstart.sh -u` to delete the deployment. This command will delete all components
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
