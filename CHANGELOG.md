RELEASE=2025.2.0
# Release Notes

## New Features/Updated functionality

### Truststore no longer provisioned by secret-agent
OpenSSL now provides the default root CAs.  User can provide additional
certificates via the Helm chart.

### Removed curl from ldif-importer

Curl has been replaced with ldapsearch in the ldif-importer job. Curl often has
security vulnerabilities, and so we decided to remove it.

## Bugfixes

## Removed Features

## Documentation updates

### Expanded section on alternate release files

Organizations that need to build their own container images can create their
own release files so `forgeops image` and `forgeops info` will work with these
custom images.
