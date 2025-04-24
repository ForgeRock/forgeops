# Using secret-generator for passwords

In the 2025.2.0 release, we added the ability to use secret-generator to create
and manage passwords and ssh keys in ForgeOps deployments. The secret-generator
is a standard method for managing secure passwords in Kubernetes. The
secret-agent will be deprecated, and support will end in the future.

## Platform secrets are commented out

The secrets in `charts/identity-platform/values.yaml` have been commented out.
This is to allow users to have control when migrating between secret-agent and
standard 3rd party Kubernetes tools. As you go through the steps below, you'll
be copying `platform.secrets` out of `charts/identity-platform/values.yaml` and
uncommenting the secrets.

It looks like this in the default values.yaml:

```
platform:
  secrets: {}
  # amster:
  #   annotations:
  #     type: ssh-keypair
```

After enabling secret-generator, it looks like this:

```
platform:
  secrets:
    amster:
      annotations:
        type: ssh-keypair
```

## List of secrets

By default, ForgeOps defines several secrets in the secret-agent config. For
the purposes of this document, we are going to categorize them into those that
can be migrated individually vs as a group.

When migrating secrets from secret-agent, you are essentially rotating them.
You need to follow the documentation on rotating secrets to see what needs to
happen after the secret has been provisioned by secret-generator.

### Individual secrets

These secrets can be migrated one at a time.

* amster
* amster-env-secrets
* ds-env-secrets

### Grouped secrets

These secrets must be moved as groups.

* am-passwords, ds-passwords, am-keystore
* idm, idm-env-secrets

## Helm

### Fresh install

If you want to use secret-generator from the start, you just need to enable it
and disable secret-agent. You will also need to enable the trust-manager option
as well.

In `helm/my_env/values.yaml`, set these values and uncomment all of
`platform.secrets`.

```
platform:
  disable_secret_agent_config: true
  secret_generator_enable: true
  secrets:
    amster:
      annotations:
        type: ssh-keypair
...Rest of the secrets...
```

At this point, you simply use Helm normally as outlined in the documentation.

### Migrate from secret-agent

You can migrate in a couple of different ways. In these different methods,
`values.yaml` refers to `helm/my_env/values.yaml`.

#### Altogether

The most straightforward way of migrating is to just do all of them together.
This may require restarting pods if `helm upgrade` doesn't restart them for
you. Refer to the documentation on rotating secrets for more information.

1. Set `platform.disable_secret_agent_config` to true in `values.yaml`
1. Set `platform.secret_generator_enable` to true in `values.yaml`
1. Delete `ldif-importer` job if it exists
1. Copy `platform.secrets` from `charts/identity_platform/values.yaml`
1. Uncomment all secrets in `platform.secrets`
1. Apply changes with `helm upgrade`
1. If pods do not restart, then do the following
    1. `kubectl rollout restart sts ds-cts -n my_env`
    1. `kubectl rollout restart sts ds-idrepo -n my_env`
    1. `kubectl rollout restart deployment am -n my_env`
    1. `kubectl rollout restart deployment idm -n my_env`

#### Individually

You can migrate by enabling secret-generator for one secret at a time. In this
method, you leave the secret-agent enabled until you have migrated all secrets
over. Refer to the section above to see which secrets must be moved together vs
individually.

1. Set platform.secret_generator_enable to true in `values.yaml`
1. Copy secret(s) to `values.yaml`
1. Uncomment the secret(s)
1. Apply changes with `helm upgrade -i ...`
1. Follow secret rotation procedure in documentation

Once all secrets have been migrated, you can set disable_secret_agent_config to
true in `values.yaml`, and apply the change.

## Kustomize

With Kustomize, you'll need to modify the `kustomize/base` to enable
secret-generator. We generate the base from the Helm chart using
`bin/base-generate.sh`, and you can provide overrides to the Helm chart per
component. Each component in `kustomize/base` has a `values.yaml` file that we
have configured to generate the base resources for that specific component. You
can create a `values-override.yaml` file to provide your own settings for that
component's base resources.

When the instructions tell you to update `values-override.yaml`, you should
update `kustomize/base/secrets/values-override.yaml`. This file does not exist
by default, so you will need to create it. When the instructions tell you to
generate the base, you run `bin/base-generate.sh`.

### Fresh install

If you are installing fresh, then it is highly recommended to start with Helm.
Kustomize is not a good option for most people, and you should only use it if
you have a compelling reason to do so.

If you are going to use Kustomize, then you need to set the same values from
the Helm fresh install section. In this case, you would add them to
`values-override.yaml`, and generate the base.

At this point, you can deploy with `forgeops apply` or `kubectl apply -k`.

### Migrate from secret-agent

If possible, we recommend first migrating away from Kustomize to the Helm
chart, and then following the Helm steps for migrating away from secret-agent.

Kustomize migration presents an extra challenge because we are making changes
in the base which impacts all deployments. In the setup section, we describe a
method for testing the changes so as to not impact your prod environments.

#### Setup

The safest way to test the migration is to copy the kustomize folder. You can
test the steps on your non-prod environments in this second kustomize dir. When
running base-generate.sh, you can provide a different kustomize dir with `-k`.

`cp -rp kustomize kustomize-test`

Populate `kustomize-test/secrets/values-override.yaml`

`bin/base-generate.sh -k kustomize-test`

If you are using a separate `FORGEOPS_ROOT`, you'll need to specify the full path to `kustomize-test`.

`bin/base-generate.sh -k /path/to/FORGEOPS_ROOT/kustomize-test`

When applying the changes with `forgeops apply`, use `-k` to specify the alternate kustomize dir.

`bin/forgeops apply -k kustomize-test -e my_env`

Once you are happy with the steps, you can upgrade your prod environment(s) in
the normal `kustomize` dir. If you choose to migrate secrets in multiple steps,
then you'll need to do all prod environments at each step.

#### Altogether

Migrating all of the secrets together is straightforward like with Helm.

1. Set `platform.disable_secret_agent_config` to true in `values-override.yaml`
1. Set `platform.secret_generator_enable` to true in `values-override.yaml`
1. Delete `ldif-importer` job if it exists
1. Copy `platform.secrets` from `charts/identity_platform/values.yaml`
1. Uncomment all secrets in `platform.secrets`
1. Generate the base
1. Apply changes with `forgeops apply` or `kubectl apply -k`
1. If pods do not restart, then do the following
    1. `kubectl rollout restart sts ds-cts -n my_env`
    1. `kubectl rollout restart sts ds-idrepo -n my_env`
    1. `kubectl rollout restart deployment am -n my_env`
    1. `kubectl rollout restart deployment idm -n my_env`

#### Individually

1. Set platform.secret_generator_enable to true in `values-override.yaml`
1. Copy secret(s) from `charts/identity-platform/values.yaml` to `values-override.yaml`
1. Uncomment the secret(s)
1. Generate the base
1. Apply changes with `forgeops apply` or `kubectl apply -k`
1. Follow secret rotation procedure in documentation

Once all secrets have been migrated, you can set disable_secret_agent_config to
true in `values-override.yaml`, and apply the change.
