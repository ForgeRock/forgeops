RELEASE=2025.2.1
# Release Notes

## New Features/Updated functionality

## Bugfixes

### Fixed backwards compatibility of PingAM images built from 2025.2.0
The import-pem-certs.sh script was moved from the PingAM docker image to a configmap. 
Because the script isn't available as a configmap in 2025.1.x, new images built from 
2025.2.0 and used in 2025.1.2 fail.  So the script has been added back to docker/am.

## Removed Features

## Documentation updates

