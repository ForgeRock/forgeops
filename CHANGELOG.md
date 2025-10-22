RELEASE=2025.2.2
# Release Notes

## New Features/Updated functionality

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

