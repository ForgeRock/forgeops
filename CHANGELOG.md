RELEASE=2025.1.1
# Release Notes  

## New Features/Updated functionality

### Ability to set FORGEOPS_ROOT

Users now have the ability to specify a separate FORGEOPS_ROOT location that contains the `docker`, `helm`, and `kustomize` folders. This allows users to keep their changes in a separate git repo. Users can create a `~/.forgeops.conf` with their personal overrides like specifying `FORGEOPS_ROOT=/path/to/my/local/checkout`. Teams can place a `forgeops.conf` file in their FORGEOPS_ROOT that contains team-wide settings. It is not recommended to create a `/path/to/forgeops_repo/forgeops.conf`.

Doing this gives users the ability to clone the forgeops repo and just checkout the version tag they need. This should make it easier to keep track of what version of ForgeOps is being used, and upgrading to a newer version.

### Removing forgeops-minikube script

The `cluster/minikube/forgeops-minikube` script was outdated, and unnecessary.
Please see:
[https://docs.pingidentity.com/forgeops/2025.1/deploy/deploy-scenario-helm-local.html](to deploy on Minikube using Helm)
[https://docs.pingidentity.com/forgeops/2025.1/deploy/deploy-scenario-kustomize-local.html](to deploy on Minikube using Kustomize)

### info command can provide release information

You can now get a list of supported platform releases and their latest flags
with `forgeops info --list-releases`. You can get details for any release on
releases.forgeops.com with `forgeops info --release x.y.z`.

### env command supports PingGateway (IG)

You can now update IG settings for cpu, memory, replicas, and pull policy in an
environment.

### pyyaml updated

The version of pyyaml has been updated. Please run `forgeops configure` to update your libraries.

## Bugfixes

### forgeops info --env-name

In the last release, the info command got a new flag to provide details about a
specific environment. It threw an error when images with a timestamp we added
to the product release files. That has been fixed.

### DS certificates are now deployed in helm pre-install
Helm pre-install hooks are now used to deploy DS certificates and they will no
longer be deleted when the helm chart is uninstalled.

### Updated AM service target port
Updated the AM service in the Helm chart to use https target port.

### Prometheus updates
Default ports and labels have been updated to match the new Helm chart.

### DS certificates are now deployed in helm pre-install
Helm pre-install hooks are now used to deploy DS certificates and they will no
longer be deleted when the helm chart is uninstalled.

### Updated AM service target port
Updated the AM service in the helm chart to use https target port.

### Prometheus updates
Default ports and labels have been updated to match the new helm chart.

## Documentation updates

