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

### New migration command

A new subcommand has been added called `forgeops migrate`. This subcommand
currently can be used to migrate secrets from secret-agent to Helm-generated
secrets.  Run `forgeops migrate -h` and `forgeops migrate sa2hs -h` for more
information.

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
PingGateway 2026.6.0

### Extra values for prereqs

You can now pass a values file to `forgeops prereqs` for cert-manager and
ingress. This allows users to provide extra values as needed. See `forgeops
prereqs -h` for more info.

### Increased TTL for Kubernetes jobs (Helm only)

The default `ttlSecondsAfterFinished` for all three jobs has been increased from 7200s
(2 hours) to 43200s (12 hours), giving more time to inspect completed or failed jobs
before they are automatically cleaned up.

### Adding PingOne secret

It is now possible to create and use a secret with ForgeOps to connect to the
PingOne Worker Service. This secret gets mounted on the AM filesystem so that
it can be used by AM. This is only part of the configuration necessary to make
this solution work. A new flag has been added to `forgeops env` to set the
secret name.

`forgeops env -e my-env --pingone-secret pingone-secrets`

## Bugfixes

### Dynamic Kubernetes job naming (Helm only)

The `amster`, `ds-set-passwords`, and `keystore-create` Kubernetes job names in the
`identity-platform` Helm chart now include the Helm release revision as a suffix
(e.g. `amster-3`, `ds-set-passwords-3`, `keystore-create-3`). This ensures each
`helm upgrade` produces a distinct job name, preventing failures caused by Kubernetes'
immutability constraint on existing jobs.

### Adding annotations for Traefik sticky sessions

The `forgeops prereqs` command installs Traefik in Nginx compatibility mode.
This was done to make it a more seamless transition from the old and
unmaintained Nginx ingress. However, some users are installing Traefik manually
and running into issues with sticky sessions not working. The traefik specific
annotations for sticky sessions has been added.

### `forgops wait` reports success prematurely

When using `forgeops wait` after doing a `kubectl rollout restart` on a DS
statefulset, the wait command would show success prematurely. This was due to
the logic looking at pods starting at 0 when rollout starts with the last pod
in the set. The logic has been changed to use `kubectl rollout status` to check
for readiness.

### Changing AM service port to http

The AM service port was set to https which was fine when the controller was
Nginx or Traefik in Nginx compatibility mode. When Traefik is run normally, it
breaks here because the port on the AM pod is not a true SSL port. Changing the
name to match reality.

## How-tos

The `custom-secrets.md` how-to has been modified to remove references to
migrating to secret-generator. The references regarding migrating from
secret-generator have been left in for any users that made the switch already.

