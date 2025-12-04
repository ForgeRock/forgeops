RELEASE=2025.2.2
# Release Notes

## New Features/Updated functionality

### Adding --output-file to bin/debug-logs

Providing the ability to send the output of bin/debug-logs directly to a file.

### New product versions available

IDM and DS 8.0.1 secure images available
AM 7.5.2 and 8.0.2 secure images available

### New --retain option for troubleshooting Amster
You can supply `--retain {duration}` to both `forgeops amster import` and `forgeops amster export` 
to keep the pod running longer.

### Increased TTL
Amster, ds-set-passwords and keystore-create jobs will now remain for two hours after completion to allow viewing logs. This value can be amended.

### Moved upgrade logic into env command

The `forgeops upgrade` logic has been moved to `forgeops env` as a flag. You
can now call it like:

`forgeops env -e my_env --upgrade`

### Display a message when requested version isn't available

The `forgeops image` command will select the next available version if the user
requests a version that isn't available for a product. Now, it will tell you
that it can't find the requested image to avoid confusion.

### Adding ability to specify external DS hosts in Helm chart

You now have the ability to specify external DS host names in your values.yaml.
See `platform.external_ds` in `charts/identity-platform/values.yaml` for more
info.

### Updated python dependency versions

The versions of the python dependencies have been updated in
`lib/python/requirements.txt`. Use `forgeops configure` to update your venv.

```
cd /path/to/forgeops
source .venv/bin/activate
./bin/forgeops configure
```

## Bugfixes

### Fixed bug in base-generate.sh
There was a step missing in the logic for `base-generate.sh` that prevented the
updated files from being placed properly. It now copies the results of `helm
template` into the proper location.

### Amster bug fixes
Providing --full to `forgeops amster export` ensures it exports all realm entities.  
This option was broken but now works.

`forgeops amster import {src}` wasn't overwriting the configuration baked in to the image 
with the provided configuration.  This has now been corrected.

`forgeops amster export` now waits for AM to be up.  Previously this function was only included 
in the import command.

## Removed Features

## Documentation updates

### Adding user supplied certs to the truststore how-to
New how-to on adding user supplied certificates to the truststore.
