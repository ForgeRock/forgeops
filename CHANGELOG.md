RELEASE=2025.2.0
# Release Notes  

## New Features/Updated functionality

### Updates to bin/certmanager-deploy.sh
The bin/certmanager-deploy.sh script has been updated to use the latest available version.  
CRDs are now deployed as part of the helm command using --set installCRDs=true.

### New PingGateway version available
PingGateway 2025.3.0 has been released and is available to deploy with forgeops tooling.

### Update PingGateway deployment to use the new default admin endpoint
Ping Gateway has 2 endpoints now:
- `/ig` the main entry point to PingGateway
- `/admin` the API of the PingGateway admin, containing the `/ping` handler used for live checks for example.

## Bugfixes

### Fix --amster-retain option
Added --amster-retain option to bin/forgeops env.  
Now user can configure environment to keep amster running for troubleshooting purposes.

## Removed Features

### Removed generate command

The deprecated `forgeops generate` command has been removed.

## Documentation updates

### New how-to explaining how to add a second DNS alias for the root realm in PingAM
New how-to called add-additional-dns-alias-to-root-realm.md which provides steps on how to configure your Helm or Kustomize  
deployment to use a second FQDN as an additional DNS alias for PingAM's root realm.
