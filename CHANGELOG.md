RELEASE=2025.1.2
# Release Notes  

## New Features/Updated functionality

### New PingGateway version available
PingGateway 2025.3.0 has been released and is available to deploy with forgeops tooling.

### Update PingGateway deployment to use the new default admin endpoint
Ping Gateway has 2 endpoints now:
- `/ig` the main entry point to PingGateway
- `/admin` the API of the PingGateway admin, containing the `/ping` handler used for live checks for example.

### Custom ENV variables in Helm chart

Implemented a customer request to provide a mechanism to define extra ENV
variables for AM and IDM as well as adding custom variables to the
platform-config ConfigMap.

Look in the following sections in charts/identity-platform/values.yaml for
examples. Update the values.yaml for your environments with the desired
configuration. The `env` arrays should contain maps of Kubernetes ENV
configurations.

platform.configMap.data # Map of custom key:value pairs for platform-config
platform.env            # Shared custom ENV vars
am.env                  # AM custom ENV vars
idm.env                 # AM custom ENV vars

### install-prereqs

The install-prereqs script has been refactored with many new features.

* Added a usage statement
* Added trust-manager as a prereq
* Added secret-generator as a prereq
* Can choose between secret-agent and secret-generator
* Added the --upgrade flag for easy upgrading of prereqs
* Added the ability to provide a config file to pin versions
* Can target specific prereqs `install-prereqs cert-manager secrets`

### Started new secret management method

We have been working on an alternate method to managing secrets that relies on
3rd party tooling instead of secret-agent. While this work has started, it is
not complete. You should not enable it in a production envirionment.

### Prometheus and Grafana added to Helm chart

Added the ability to enable Prometheus and Grafana in the Helm chart.

### Increased TTL for keeping amster and ldif-importer jobs

Increased the TTL for keeping the amster and ldif-importer jobs from 300 to 600 seconds.

### Improved release detection

When using `forgeops image` and `forgeops info`, it can now look forward for a
release if a customer select X.0.0 and it doesn't exist. This was added due to
AM/Amster 8.0.0 being skipped making 8.0.1 the first version.

## Bugfixes

### Fix --amster-retain option
Added --amster-retain option to bin/forgeops env.
Now user can configure environment to keep amster running for troubleshooting purposes.

### Fix VolumeSnapshots in Kustomize deployments

The `forgeops env` command has been updated to add a patch to update the
namespace when enabling volume snapshots for DS.

## Removed Features

### Removed generate command

The deprecated `forgeops generate` command has been removed.

### bin/certmanager-deploy.sh

The old certmanager-deploy.sh script has been removed in favor of charts/scripts/install-prereqs.

### bin/secret-agent

The old secret-agent script has been removed in favor of charts/scripts/install-prereqs.

## Documentation updates

### New how-to explaining how to add a second DNS alias for the root realm in PingAM
New how-to called add-additional-dns-alias-to-root-realm.md which provides steps on how to configure your Helm or Kustomize  
deployment to use a second FQDN as an additional DNS alias for PingAM's root realm.
