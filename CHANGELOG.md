RELEASE=2026.3.1

# Release Notes

## New Features/Updated functionality

### New dsconfig subcommand

A new subcommand has been added that allows users to execute dsconfig commands
against a DS pod. It uses the secrets in your namespace to determine the
connection options needed and automatically passes them to dsconfig on a DS pod
of your choosing. Strings with spaces need to be handled properly by double
quoting or quoting and escaping spaces. See `forgeops dsconfig --help` for more
information.

### Removing dryrun short flag

The dryrun short flag (`-r`) conflicts with `--push-to`, and is generally not
necessary. Removing as part of a project to normalize flags across commands.

## Bugfixes

### Incorrect image tag for ssh-keygen job's init container

A new job was added as part of the Helm generated secrets feature in 2026.3.0.
During the release process, any latest tag is replaced with a build tag created
as part of that process. This clobbered the tag for ssh-keygen's init
container. The image tag is now pinned to a digest. Currently, only ssh-keygen
has the ability to specify a digest as a tag.

### forgeops env --upgrade didn't honor --no-helm or --no-kustomize

The `forgeops env --upgrade` command wasn't properly honoring `--no-helm` and
`--no-kustomize` which caused errors for folks using them. It has been updated
to properly honor those flags.

## How-tos

