RELEASE=2026.3.2

# Release Notes

## New Features/Updated functionality

### New README for customizing the PingDS deployment setup
New README with some useful customization steps for PingDS including adding custom LDAP entries and schema files.

## Bugfixes

### forgeops dsconfig leaked password

The `forgeops dsconfig` command leaked the dirmanager password into Kubernetes
logs. It has been changed to pass the command to `sh` via stdin. This means
Kubernetes will log a call to sh instead of dsconfig.

### info --json included extra output

`forgeops info --release x.y.z --json` now only outputs valid json to stdout.

## How-tos

### New Procedures

[Migrate to Helm from Kustomize](how-tos/kustomize-to-helm.md)
