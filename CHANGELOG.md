RELEASE=2026.2.0

# Release Notes

## New Features/Updated functionality

### Added initContainers to enable readOnlyRootFilesystem (Helm only)

The init containers have been reworked to allow users to enable the
readOnlyRootFilesystem securityContext. This has no impact on the Deployments,
but requires that the StatefulSets (DSes) be recreated.

### Added --secure/--insecure flags to env (Helm only)

With the addition of support for security features like readOnlyRootFilesystem,
you are now able to toggle all security features with these new flags. By
default, new envs will be created with --secure enabled.

To enable the secure features on an existing env run the following command,
then follow the instructions in <./how-tos/recreating-ds-sts.md> to apply the
change.

`forgeops env -e my-env --secure`

### No longer supporting 7.4 Ping Identity Platform images

ForgeOps supports the last three major/minor versions of the Ping Identity Platform images.  
With the availability of 8.1 images, ForgeOps supports 8.1, 8.0, and 7.5 versions of the  
platform images, and 7.4 images are no longer supported. We recommend customers to upgrade  
to newer version of the platform images. Refer to the [upgrade guide](https://docs.pingidentity.com/forgeops/2026.2/upgrade/upgrade-product.html). The older tags remain  
available on http://releases.forgeops.com until the next major/minor release.

### New amster and ds-set-passwords ttl options for `forgeops env` command(New envs only)

New options added to the `forgeops env` command to allow the user to set the length  
of the ttlSecondsAfterFinished value in the amster and ds-set-passwords jobs.
Default is set to 7200 seconds.

## Bugfixes

## How-tos

### recreating-ds-sts

This how-to describes how to recreate a DS sts without downtime when you need
to make a significant change to a STS. <./how-tos/recreateing-ds-sts.md>
