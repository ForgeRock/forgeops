RELEASE=2026.1.0

# Release Notes

## Highlights in this release

### Ability to provide file based config as a ConfigMap

The `forgeops config` command has a new `configmap` subcommand to create
ConfigMaps for AM, IDM, or IG with the FBC config profile as tgz files.
Helm chart and the Kustomize base have been updated to use the ConfigMap if it 
exists. If it doesn't exist, then it will use the built-in config in images as 
before. Now it is no longer necessary to build the config into images.

Refer to the [Apply AM configmap](https://staging-docs.pingidentity.com/forgeops/dev/customize/am.html#apply-am-configmap) and 
[Apply IDM configmap](https://staging-docs.pingidentity.com/forgeops/dev/customize/idm.html#apply-idm-configmap) sections in the documentation for further information.

## New Features/Updated functionality

### Direct `debug-logs` output to a file

Added the ability to send the output of `bin/debug-logs` directly to a file.

### New product versions available

The following new versions are available:
- IDM and DS 8.0.1 secure images 
- AM 7.5.2 and 8.0.2 secure images
- Secret Agent 1.2.8 

### New `--retain` option for troubleshooting Amster

You can use the `--retain {duration}` option with `forgeops amster import` and 
`forgeops amster export` commands to keep the pod running longer.

### Increased TTL

Amster, ds-set-passwords and keystore-create jobs will now remain for two hours 
after completion to allow viewing logs. This value can be amended.

### Moved upgrade logic into env command

The `forgeops upgrade` logic has been moved to `forgeops env` as a flag. You
can now call it like:

`forgeops env -e my_env --upgrade`

### Display a message when requested image version isn't available

The `forgeops image` command will select the next available version if the user
requests a version that isn't available for a product. Now, it will tell you
that it can't find the requested image to avoid confusion.

### Ability to specify external DS hosts in Helm chart

Added the ability to specify external DS host names in your `values.yaml`.
See `platform.external_ds` in `charts/identity-platform/values.yaml` for more
info.

### Updated python dependency versions

The python dependencies have been updated in `lib/python/requirements.txt`. 
Use `forgeops configure` to update your venv.

```
cd /path/to/forgeops
source .venv/bin/activate
./bin/forgeops configure
```

### Grafana dashboards to update 

The Grafana dashboards in
`etc/addons/prometheus/forgerock-metrics/dashboards` has been updated with
the latest ones provided by the Product teams.

### Ability to build am-config-upgrader image

Added `am-config-upgrader/Dockerfile` and the ability to build an
`am-config-upgrader` image with `forgeops build`.

### Repository clean up

The `forgeops` repository has been cleaned up by moving several items around. 
This is being done to focus the forgeops repository on the essential artifacts 
needed to manage ForgeOps deployments.

* Moved examples from `etc` folder to the `samples` folder in `forgeops-extras` 
repository.
* Moved the contents of the `cluster` folder into the `etc` folder.
* Removed the scripts in the old `bin` folder, as their functionality is now 
provided through the `forgeops` tool.
  * bin/amster -> `forgeops amster`
  * bin/config -> `forgeops config`
  * bin/am-config-upgrader -> `forgeops upgrade-am-config`

## Bugfixes

### Fixed bug in `base-generate.sh`

There was a step missing in the logic for `base-generate.sh` that prevented the
updated files from being placed properly. It now copies the results of `helm
template` into the proper location.

### Fixed bugs in `amster`

Included the `--full` option in `forgeops amster export` to enable exporting 
all realm entities. The bugs in this option have been fixed.

`forgeops amster import {src}` wasn't overwriting the configuration baked in to 
the image with the provided configuration.  This has now been corrected.

`forgeops amster export` now waits for AM to be up.  Previously this function 
was only included in the import command.

### Fixed `forgeops upgrade-am-config`

The 8.0.2 `am-config-upgrader` image changed permission on some files which 
caused `forgeops upgrade-am-config` to break. The `forgeops upgrade-am-config` 
command now connects to the container as `root`. This is an ephemeral 
container running outside the cluster and reduces the security impact.

## How-tos

### Included new procedures

* [Add user supplied certificates](how-tos/custom-secrets.md) to the truststore.
* [Change FQDN in a ForgeOps deployment](how-tos/change-fqdn-in-running-deployment.md).

