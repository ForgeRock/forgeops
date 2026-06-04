RELEASE=2026.3.0

# Release Notes

## New Features/Updated functionality

### Secret Generator option removed

The ability to select Secret Generator with the env command has been removed.
Unfortunately, the project doesn't publish arm64 images, and community
requests are not being responded to. As such, we cannot recommend it for
customer use.

### Helm generated secrets

Secret generation using native Helm functions has been added to the Helm chart.
This allows for random passwords to be generated without relying on an operator
to do it.

### ssh-keygen job

Helm cannot generate ssh keys, so a job was created to generate an ssh key and
store it in a secret. This is used by amster to connect to am.

### Helm chart for RCS

A new Helm chart has been created for RCS Server. This allows users to sync
data to/from a ForgeOps deployment. More information can be found in
<./charts/rcs/README.md>.

### Secret Agent v1.2.12

Secret Agent has been updated to v1.2.12 to patch security issues. The prereqs
command has been updated to install this new version.

### New product patch release versions
8.1.1 patch versions for all Ping Advanced Identity Software products.
PingIDM 8.0.2

### Extra values for prereqs

You can now pass a values file to `forgeops prereqs` for cert-manager and
ingress. This allows users to provide extra values as needed. See `forgeops
prereqs -h` for more info.

### Increased TTL for Kubernetes jobs (Helm only)

The default `ttlSecondsAfterFinished` for all three jobs has been increased from 7200s
(2 hours) to 43200s (12 hours), giving more time to inspect completed or failed jobs
before they are automatically cleaned up.

## Bugfixes

### Dynamic Kubernetes job naming (Helm only)

The `amster`, `ds-set-passwords`, and `keystore-create` Kubernetes job names in the
`identity-platform` Helm chart now include the Helm release revision as a suffix
(e.g. `amster-3`, `ds-set-passwords-3`, `keystore-create-3`). This ensures each
`helm upgrade` produces a distinct job name, preventing failures caused by Kubernetes'
immutability constraint on existing jobs.