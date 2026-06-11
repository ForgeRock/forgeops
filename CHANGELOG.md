RELEASE=2026.2.1

# Release Notes

## New Features/Updated functionality

### SBOMs for images

We know produce Software Bill of Materials (SBOM) for our images. You can find
them at http://releases.forgeops.com/sbom . See
<./how-tos/retrieve-SBOMs-based-on-original-image-URL.md> for more details on
using them.

## Bugfixes

### Fixed VolumeSnapshot cleanup

When using the provided VolumeSnapshot capability, the purgeDelay setting was
not being honored. The logic to determine that was changed to use the more
reliable seconds since epoch.

### Added volume for Tomcat temp dir

When readOnlyRootFilesystem is enabled for AM, it can throw an error when a
user tries to edit a script via the UI. The tomcat temp dir is now mounted
separately as an emptyDir volume.

## How-tos

### recreating-ds-sts

This how-to describes how to recreate a DS sts without downtime when you need
to make a significant change to a STS. <./how-tos/recreateing-ds-sts.md>
