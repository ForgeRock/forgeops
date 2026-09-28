# Configuring Realms in ForgeOps

Configuring realms in ForgeOps is a complex endeavor that has been left up to
implementors. To remedy this, `forgeops realm` was created to help users manage
the process of creating a realm.

## Experimental Feature

Please be aware that this is an experimental feature implemented to support AIC
customers in creating a self-hosted DR for their AIC tenant. Non-AIC customers
should use caution when using `forgeops realm` and test their configurations
fully before committing to production deployments. Be aware that this
implementation is likely to change in the future as realms mature across the
platform.

# Known limitations

Realms are not fully supported across the entire platform and so you may
encounter some issues. For example, the platform UI is not realm aware and so
when creating users, an error will briefly pop up on screen. There are likely
other issues such as this and we encourage people to file a support ticket when
they encounter one.

# Old alpha/bravo realm setup

Previously, a DS config was provided for alpha and bravo realms as an example,
and was baked into DS images. Unfortunately, the alpha config contained an
error, and the DS config is a tiny part of the overall process of creating a
realm. Going forward, that config has been converted into templates that are
used by `forgeops realm create`. This means that the DS entries for alpha and
bravo will no longer be present in fresh DS installs.

If you made changes to `alpha_bravo.ldif` and/or `orgs.ldif`, please follow the
instructions in the "Existing deployments with realms" section of this
document.

# Setup

Before running `forgeops realm`, you should consider a few things. Primarily,
you should consider how you want to structure your realms and read up on realms
in the AM documentation.

You should be sure that you are starting from a clean git checkout on a feature
branch. Do not mix these changes with other changes.

## Fresh deployment

When configuring realms for a fresh deployment, you'll want to start by
creating a single-instance env to develop your config against. This env will
only have one pod per application to allow for config export.

`forgeops env -e stage-single -f stage-single.example.com --cluster-issuer my-issuer --idm-admin-ui-enable`

You can then create a real environment that we deploy and apply the realms to later on.

`forgeops env -e stage -f stage.example.com --cluster-issuer my-issuer --idm-admin-ui-enable`

## Existing deployment

For an existing deployment, make sure your single-instance env and deployment
are up to date with your production env and deployment. The `forgeops realm
apply` command copies images from the single-instance env to the real env so be
sure that the images are synced up as part of this step.

# Create a realm

## Single instance only

Creating a realm must happen in an single-instance deployment because of the
file-based config changes. This also allows you to test your new realm before
applying it to your production deployment. The `forgeops realm create` command
will check to make sure that you are running against a single-instance
deployment, and will exit if you are not.

## Config profiles

The `forgeops realm create` command needs a config profile to save the FBC
into. The command assumes that the config-profile name given matches between AM
and IDM. Be sure that your config-profile name matches between them. The
command also creates an amster config-profile, but it is named
`realm-REALM_NAME` instead of the config profile name provided on the command
line. This is so that it can be applied to the real deployment during that
step.

## Creating the realm

The `forgeops realm create` command takes a significant number of actions
against your single-instance deployment. This includes creating and applying
ldifs to ds-idrepo, creating the realm via the AM API, creating an amster
profile for the realm, updating AM and IDM config-profiles, building images,
and running Helm. There are no pauses between steps, and it is safe to rerun
the command if you run into issues.

In this example, a new realm called accounting will be created. To create this
realm in the single-instance deployment, run the following command.

`forgeops realm create -e stage-single -n stage-single -p stage --push-to my-container-repo -t $(date +%Y%m%d%H%M) accounting`

This will execute all of the steps to create the realm. Once the command has
finished and all pods are ready, then you can test out the new realm in your
single-instance deployment. 

### Kustomize

For Kustomize users, the command will not apply the changes to the
single-instance deployment. You will need to do that manually with `forgeops
apply`.

`forgeops apply -e stage-single -n stage-single`

## Applying the realm to a real deployment

Now that you have created and tested the realm in your single-instance
deployment, you can apply it to your real deployment. For this command, you
need to provide the real env and the single-instance env as the source. This is
so the images can be copied from the single-instance env to the real env.

`forgeops realm apply -e stage -s stage-single -n stage accounting`

Once the command has completed and all pods are ready, the realm is ready to be
used.

### Kustomize

For Kustomize users, the command will not apply the changes to the real
deployment. You will need to do that manually with `forgeops apply`.

`forgeops apply -e stage -n stage`

Once the new images are deployed and all pods are ready, you need to apply the
amster config profile with `forgeops amster import`.

`forgeops amster import -e stage -n stage realm-accounting`

# Existing Deployments with Realms

If you have an existing deployment configured with realms, you can use the new
`forgeops realm` command to add new realms. You can also use it to generate the
files for your realms so that you can apply them again in the future if needed.
Running the commands on already existing realms is safe. It will skip the steps
to apply an ldif or create the realm in AM if it finds that those things have
already happened.

After you have run the commands to create the new files, you should clean up
your old ldif files in `docker/ds/ldif-ext/am-config` and
`docker/ds/ldif-ext/identities`. You should completely remove
`docker/ds/ldif-ext/am-config/alpha_bravo.ldif`.

While it's not strictly necessary to run `forgeops realm apply`, it is a good
idea to make sure your real deployment is in sync with your single-instance
deployment.

## Manually reorganizing existing realm configs

You can manually reorganize your existing config to match what `forgeops realm`
expects. Your FBC should already be configured, so this is mostly about making
sure your ldif files are organized in the new method.

If you have been adding your realms to alpha_bravo.ldif and orgs.ldif, you will
need to break those out into individual files per realm.

### AM config ldifs

In `docker/ds/ldif-ext/am-config`, the `alpha_bravo.ldif` file has been removed.
In its place is `realm.ldif.tmpl` which gets copied to `REALM_NAME.ldif`. You
can emulate this in one of two ways.

One way is to copy the template to the new file, then do a search and replace
`REALM_NAME` with your realm name.

Another way is to copy the entries in the old `alpha_bravo.ldif` into a new
`REALM_NAME.ldif`. 

Do this for all of your exising realms, then delete the old `alpha_bravo.ldif`.

### IDM config ldifs

In `docker/ds/ldif-ext/identities`, there is `orgs.ldif` which contained
example entries for the alpha and bravo realms. Those alpha/bravo entries have
been removed, and a new `realm-orgs.ldif.tmpl` was created. Much like the AM
ldif files, you need to split your existing realms into their own
`REALM_NAME-orgs.ldif` files. Do this by either copying the template, or
splitting them out from the `orgs.ldif` file.

This file also had a spurious teammember entry which is an AIC-only config, and
isn't relevant to ForgeOps. It should be removed. When you are done, there
should only be 3 entries left in `orgs.ldif`.

### Amster config profile

There is no easy way to recreate the amster config profile manually, but it
isn't necessary unless you need to recreate realms in the future. If that
unlikely scenario happens, then it's best to create the realms from scratch
with `forgeops realm`.
