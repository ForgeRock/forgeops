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

## Bugfixes

### forgeops env --upgrade didn't honor --no-helm or --no-kustomize

The `forgeops env --upgrade` command wasn't properly honoring `--no-helm` and
`--no-kustomize` which caused errors for folks using them. It has been updated
to properly honor those flags.

## How-tos

