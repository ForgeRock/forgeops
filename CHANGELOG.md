RELEASE=2026.2.0

# Release Notes

## New Features/Updated functionality

### New product versions available

* Secret Agent 1.2.11

### New amster and ds-set-passwords ttl options for `forgeops env` command(New envs only)

New options added to the `forgeops env` command to allow the user to set the length  
of the ttlSecondsAfterFinished value in the amster and ds-set-passwords jobs.
Default is set to 7200 seconds. 

## Bugfixes

## How-tos

### recreating-ds-sts

This how-to describes how to recreate a DS sts without downtime when you need
to make a significant change to a STS.
