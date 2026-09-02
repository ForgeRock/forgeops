RELEASE=2026.4.0

# Release Notes

## New Features/Updated functionality

## Bugfixes

### forgeops dsconfig leaked password

The `forgeops dsconfig` command leaked the dirmanager password into Kubernetes
logs. It has been changed to pass the command to `sh` via stdin. This means
Kubernetes will log a call to sh instead of dsconfig.
