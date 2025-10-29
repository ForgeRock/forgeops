RELEASE=2025.2.2
# Release Notes

## Highlights in this release

### Traefik is now the default `prereqs` ingress controller

The `prereqs` script now deploys Traefik proxy by default instead of Nginx
Ingress.

### Upgrade your environments

The new custom image requires changes to your environments and your default
environment if you are using the FORGEOPS_DATA functionality. Run `forgeops
env` against your environments with the `--upgrade` flag.

`forgeops env -e my_env --upgrade`

### New image for customizations

The `forgeops config` command has a new `build` subcommand to create custom
busybox images for AM and IDM with the FBC config profile.  The deployment (Helm 
and Kustomize) have been updated to use the FBC on these images if it
exists. If it doesn't exist, then it will use the built-in config in images as
before. Now it is no longer necessary to build the config into images.

* See `forgeops config build --help` for more info

## New Features/Updated functionality
- debug-logs script : provide --output-file option

### New product versions available
IDM and DS 8.0.1 secure images available
AM 7.5.2 secure images available

## Bugfixes

### Fixed bug in base-generate.sh

There was a step missing in the logic for `base-generate.sh` that prevented the
updated files from being placed properly. It now copies the results of `helm
template` into the proper location.

## Removed Features

## Documentation updates
