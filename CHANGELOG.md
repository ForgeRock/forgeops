RELEASE=2025.2.0
# Release Notes

## New Features/Updated functionality

### New PingIDM versions available
PingIDM 7.4.1 and 7.5.2 have been released and are available to deploy with forgeops tooling.

### Truststore no longer provisioned by secret-agent

OpenSSL now provides the default root CAs.  User can provide additional
certificates via the Helm chart.

### Removed curl from ldif-importer

Curl has been replaced with ldapsearch in the ldif-importer job. Curl often has
security vulnerabilities, and so we decided to remove it.

### Replace curl with wget in Amster

Curl has been replaced with wget in the amster job. Curl often has
security vulnerabilities, and so we've changed it to wget which is more secure.

### Added ability to use secret-generator

Is is now possible to use secret-generator to provision platform secrets
instead of secret-agent. In the future, secret-agent will be deprecated. It is
recommended that new deployments use secret-generator.

### New forgeops prereqs command

This replaces `charts/scripts/install-prereqs`, and the settings move into
`forgeops.conf`. See `forgeops prereqs -h` for more information.

### Added ability to do no downtime DS password rotations

DS images must be built with ForgeOps 2025.2.0 in order to enable multiple
password values. Rebuild your current images, or use the latest available tag
for DS images.

### Added `forgeops rotate` command

This assists with doing no downtime password rotations for ds-env-secrets and
ds-passwords.

## Bugfixes

### Fix `forgeops amster import/export` command
Reordered the patches in the amster/upload and amster/export sub overlays to correctly manage amster configuration.

### Stop AM failing if openam container restarts
Ensure openam container has access to the default boot.json when something causes the 
container to restart.  This is because the fbc-init init-container doesn't run when the 
openam container restarts so the default boot.json isn't set for startup.

## Removed Features

## Documentation updates

### Expanded section on alternate release files

Organizations that need to build their own container images can create their
own release files so `forgeops image` and `forgeops info` will work with these
custom images.
