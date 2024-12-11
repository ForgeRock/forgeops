# Release Notes  

## New Features/Updated functionality

### main branch is now always the current release branch
Master branch is no longer used.
dev images are now available using the `bin/forgeops image` command.

### New forgeops command:
* bin/forgeops-ng is now bin/forgeops
* Provision environments for Kustomize and Helm with `bin/forgeops env`.
* Set image tag for environment or Dockerfiles with `bin/forgeops image`.
* View configured environments and product versions with `bin/forgeops info`.  

Refer to the [ForgeOps deployment documentation](https://docs.pingidentity.com/forgeops/2025.1/deploy/deploy.html) for more information.

### ForgeOps-provided Docker images are now supported
Ping Identity now supports ForgeOps-provided Docker images. Accordingly, the documentation is revised, and the "unsupported" admonition is removed.

### New supported product versions
Platform UI versions: 7.5.1
PingAM versions: 7.4.1, 7.5.1
PingDS: 7.4.3, 7.5.1
PingGateway: 2024.6.0, 2024.9.0, 2024.11.0

### Removed legacy DS docker directories
Removed the legacy docker/ds/idrepo and docker/ds/cts directories.
docker/ds/ds-new is now just docker/ds.

### Removed requirement to build ldif-importer
ldif-importer now just uses the DS image.  Scripts are mounted via a configmap.

## Documentation updates

### New forgeops command reference
Find doc page [here](https://docs.pingidentity.com/forgeops/2025.1/start/release-process.html)

### Description of the release process
Learn more about the ForgeOps release process [here](https://docs.pingidentity.com/forgeops/2025.1/reference/forgeops.html)

### New section on customizing DS image
We’ve added a section on customizing DS image. Learn more about customizing DS image [here]([forgeops command reference](https://docs.pingidentity.com/forgeops/2025.1/customize/ds.html).

### Moved Base Docker Image page to the Reference section
Considering the ForgeOps-provided docker images are supported, the need for building base docker images is only required in special cases. Accordingly, the [Base Docker Images](https://docs.pingidentity.com/forgeops/2025.1/reference/beyond-the-docs.html) section has been moved to the Reference section.
