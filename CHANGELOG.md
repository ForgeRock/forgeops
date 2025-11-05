RELEASE=2025.2.2
# Release Notes

## New Features/Updated functionality
- debug-logs script : provide --output-file option

### New product versions available
IDM and DS 8.0.1 secure images available
AM 7.5.2 secure images available

### New --retain option for troubleshooting Amster
You can supply `--retain {duration}` to both `forgeops amster import` and `forgeops amster export` 
to keep the pod running longer.

## Bugfixes

### Fixed bug in base-generate.sh
There was a step missing in the logic for `base-generate.sh` that prevented the
updated files from being placed properly. It now copies the results of `helm
template` into the proper location.

### Amster bug fixes
Providing --full to `forgeops amster export` ensures it exports all realm entities.  
This option was broken but now works.

`forgeops amster import {src}` wasn't overwriting the configuration baked in to the image 
with the provided configuration.  This has now been corrected.

`forgeops amster export` now waits for AM to be up.  Previously this function was only included 
in the import command.

## Removed Features

## Documentation updates

### Adding user supplied certs to the truststore how-to
New how-to on adding user supplied certificates to the truststore.
