RELEASE=2025.2.1
# Release Notes

## New Features/Updated functionality

### Changing base-generate.sh

The `base-generate.sh` script creates `kustomize/base` from the Helm chart. It
has been updated to use `--output-dir` with `helm template` to generate
individual template files. This allows us to remove logic from the Helm chart
that's only there for `base-generate.sh`. Update your
$FORGEOPS_DATA/kustomize/base with these changes.

### Adding ability to provide custom secrets

The `platform.secrets` functionality added in 2025.2.0 has been updated to
allow for fully custom secrets. This enables users to use an alternate secrets
provider like `external-secrets`, or add extra secrets without having to use
secret-generator. The Helm value `platform.secret_generator_enable` has been
renamed to `platform.secrets_enabled`.

## Bugfixes

### Fixed backwards compatibility of PingAM images built from 2025.2.0
The import-pem-certs.sh script was moved from the PingAM docker image to a configmap. 
Because the script isn't available as a configmap in 2025.1.x, new images built from 
2025.2.0 and used in 2025.1.2 fail.  So the script has been added back to docker/am.

### Bitnami images going away

The Bitnami images have been pulled from Docker Hub, and are no longer
available. We have switched to the Alpine kubectl image for the keystore-create
and ds-snapshot jobs.

## Removed Features

## Documentation updates

### How To on custom secrets

Added `how-tos/custom-secrets.md` that describes how to create custom secrets
with secret-generator. It also describes how to use the same `platform.secrets`
dictionary to use an alternate Kubernetes secrets provider.
