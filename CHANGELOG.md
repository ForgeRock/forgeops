RELEASE=2025.1.1
# Release Notes  

## New Features/Updated functionality

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

## Documentation updates

