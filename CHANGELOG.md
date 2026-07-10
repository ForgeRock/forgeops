RELEASE=2026.3.0

# Release Notes

## New Features/Updated functionality

### Helm chart for RCS

A new Helm chart has been created for RCS Server. This allows users to sync
data to/from a ForgeOps deployment. More information can be found in
<./charts/rcs/README.md>.

### Secret Agent v1.2.12

Secret Agent has been updated to v1.2.12 to patch security issues. The prereqs
command has been updated to install this new version.

### New product patch release versions
8.1.1 patch versions for all Ping Advanced Identity Softward products.
PingIDM 8.0.2

### Extra values for prereqs

You can now pass a values file to `forgeops prereqs` for cert-manager and
ingress. This allows users to provide extra values as needed. See `forgeops
prereqs -h` for more info.

## Bugfixes

## How-tos

