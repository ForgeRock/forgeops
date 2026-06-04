RELEASE=2026.2.1

# Release Notes

## New Features/Updated functionality

## Bugfixes

### Fixed VolumeSnapshot cleanup

When using the provided VolumeSnapshot capability, the purgeDelay setting was
not being honored. The logic to determine that was changed to use the more
reliable seconds since epoch.

## How-tos

### recreating-ds-sts

This how-to describes how to recreate a DS sts without downtime when you need
to make a significant change to a STS. <./how-tos/recreateing-ds-sts.md>
