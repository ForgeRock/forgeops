RELEASE=2026.3.2

# Release Notes

## Kustomize deprecation

Support for Kustomize-based deployments is deprecated. Users should migrate to Helm chart-based deployments.  
You can use the <a href="how-tos/migrate-kustomize-to-helm.md">Migrate Kustomize to Helm</a> guide in the ForgeOps repository.

Deprecated in: 2026.3.2

Expected removal: 12 months after 2026.3.2 release

## New Features/Updated functionality

### Adding idm-admin-ui for 8.1.0+

In 8.1.0, the IDM legacy admin-ui was deprecated and removed. It is now
possible to add it back as a separate nginx pod in a Helm deployment.  The
image command will also set the image information if the version requested
is >= 8.1.0.

`forgeops env -e my-env --idm-admin-ui-enable`

Note that the IDM API URL path is now `/api` instead of `/openidm/api`.

### Updated README for customizing the PingDS deployment setup

Updated [README](docker/ds/README.md) with some useful customization steps for
PingDS including adding custom LDAP entries and schema files.

### releases.forgeops.com now served over HTTPS
The image tag files hosted at releases.forgeops.com are now available over HTTPS. If you set `RELEASES_SRC` in your own `forgeops.conf`, update it to use `https://`.

## Bugfixes

### forgeops dsconfig leaked password

The `forgeops dsconfig` command leaked the dirmanager password into Kubernetes
logs. It has been changed to pass the command to `sh` via stdin. This means
Kubernetes will log a call to sh instead of dsconfig.

### info --json included extra output

`forgeops info --release x.y.z --json` now only outputs valid json to stdout.

### ds-set-passwords uses ds-idrepo image

The ds-set-passwords image was not getting updated by `forgeops image`. Now, it
will use the ds-idrepo image unless you specify a `ds_set_passwords.image`
block in your values.yaml. If you specify this, it's highly recommended that
you specify the `repository`, `tag`, and `pullPolicy` keys.

This changes the default pullPolicy for ds-set-passwords from Always to
IfNotPresent.

### forgeops config build fixed

The `forgeops config build` command had a bug preventing it from executing.
This has been fixed.

### topologySpreadConstraint configs fixed

The topologySpreadConstraint blocks for ds-cts and ds-idrepo were misconfigured.

* The matchLabels was changed from `app.kubernetes.io/instance` to `app.kubernetes.io/component`
* The topologyKey was changed from `topology.kubernetes.io/hostname` to `kubernetes.io/hostname`
* Upgrading will rolling update the DS pods

## How-tos

### New Procedures

[Migrate to Helm from Kustomize](how-tos/kustomize-to-helm.md)
[PingDS Customization Guide](how-tos/pingds-customization-guide.md)

### Updated Procedures
[Adding Custom Certs to truststore](how-tos/adding-user-supplied-certs-to-truststore.md)
[Retrieve SBOMs based on original image URL](retrieve-SBOMs-based-on-original-image-URL)

### Renamed Procedures
how-tos/enabling-pingam-rest-apis.md -> (how-tos/pingam-enabling-rest-apis.md)
how-tos/recreating-ds-sts.md -> (how-tos/pingds-recreating-sts.md)
how-tos/use-an-externally-deployed-ds-with-a-forgeops-deployment.md -> (how-tos/pingds-use-an-externally-deployed-ds-with-a-forgeops-deployment.md)
