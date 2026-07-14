# Using Custom Secrets with ForgeOps

## Introduction

As of 2025.3.0, you can define custom secrets in your ForgeOps environments
with the `platform.secrets` functionality.  You can add extra secrets or you
can replace the default secrets provisioned by ForgeOps. This allows you
flexibility in your deployments based on the needs of your security policy.

This is a Helm change only, and Kustomize users remain on secret-agent.
Kustomize users should migrate to Helm.

## How the new secrets work

When you set `platform.secrets_enabled` to `true`, it enables the
`platform-secrets.yaml` template in the Helm chart which reads
`platform.secrets` in your values.yaml. This gets populated with our defaults
when you enable `helm-secrets` with `forgeops env`.

Please note that the `platform-secrets.yaml` template replaces `_` with `-` in
secret names. So `ds_env_secrets` in `values.yaml` creates a secret named
`ds-env-secrets`.

### Helm Secrets

All of our default secrets are created using Helm functions. This is triggered
when a secret has a `generate` dictionary that defines keys that get added to
the data section of the secret. You can use this to add any custom secrets that
you need.

### Alternate secrets provider

If you want to use an alternate secrets provider, then you can do that as well.
You'll need to make sure you have the prerequisites installed for your chosen
provider before deploying.  If you want to change from Helm secrets to an
alternative provider, then that is a migration and you should refer to that
section below.

The `platform.secrets` dictionary has the attributes of the various secrets
needed for a ForgeOps deployment. For example, the `amster_env_secrets` looks
like this with Helm secrets:

```
    amster_env_secrets:
      generate:
        IDM_PROVISIONING_CLIENT_SECRET:
          length: 24
        IDM_RS_CLIENT_SECRET
          length: 24
```

This tells us that the secret `amster-env-secrets` contains two secrets
(IDM_PROVISIONING_CLIENT_SECRET and IDM_RS_CLIENT_SECRET) that are text strings
24 characters long.

It's recommended to do a single instance deployment and investigate the secrets
that get deployed so you can compare against the secrets you create via your
alternate method.

For a custom setup like this it is advised to setup a separate repo to hold
your ForgeOps data. See the production-workflow how-to for details on setting
one up for your team.

## Enabling custom secrets

To enable custom secrets for a fresh deployment, you can use the `forgeops env` command.

`forgeops env -e MY_ENV --helm-secrets -f iam.example.com --cluster-issuer MY_ISSUER`

If you have already created an environment, but not yet deployed it, then you can just enable it.

`forgeops env -e MY_ENV --helm-secrets -n MY_NS`

If you have deployed but haven't gone live with it, you can reinstall your deployment.

```
forgeops env --env-name MY_ENV --helm-secrets -n MY_NS`
helm uninstall identity-platform -n MY_NS
helm upgrade -i identity-platform identity-platform --repo https://ForgeRock.github.io/forgeops --version 2025.2.1 -f helm/MY_ENV/values.yaml
```

Your DS data will be on PVCs that are not destroyed by `helm uninstall`, and
your newly deployed DS pods will connect to those PVCs with your data.

For an existing deployment that is in production, you'll need to migrate which
is an involved process. This will be described in more detail in its own
section.

You can add your secret to the `platform.secrets` list. You can then use custom
env configurations to map them into your pods.

First let's create a normal secret with a couple of random strings that are 26
characters long.

```
platform:
  secrets:
    my_secret:
      generate:
        MY_SECRET_DATA_1
          length: 26
        MY_SECRET_DATA_2
          length: 26
```

We can then map that secret into one or more pods. This is possible for AM,
IDM, DS, and IG in the values file. In this case, let's map it to AM.

```
am:
  envFrom:
    - secretRef:
        name: my-secret
```

If you want to map it into all of them, then you can use `platform.envFrom`.

```
platform:
  envFrom:
    - secretRef:
        name: my-secret
```

You can now deploy the new configuration with `helm upgrade`.

## Migration

To migrate from secret-agent or secret-generator to a custom secret provider,
there is a set of meta steps you need to follow and incorporate into your
migration procedures.

### Prereqs

First, you need to install the prereqs for your chosen secrets provider. This
may include things like installing a Helm chart or creating external resources.

It is recommended that you ensure `allow-multiple-password-values` is set to
true in the "Default Password Policy" and the "Root Password Policy" so you can
use the password rotation logic to avoid downtime. You can use the `dsconfig`
command to set this, or you can build new DS images with ForgeOps 2025.2.1 or
higher.

You need to understand your secrets provider and what your process will be for
rotating secrets. You should document this for your team so they know what to
do when using `forgeops rotate` for password rotations in the future.

### Phase 1

Now we move into removing the first batch of secrets. The 4 secrets we will be
removing are `am-env-secrets`, `ds-env-secrets`, `amster`, and
`amster-env-secrets`.

#### Create old-ds-env-secrets

Before we delete `ds-env-secrets`, we need to use the `forgeops rotate` command
to create `old-ds-env-secrets` so AM doesn't lose connectivity to DS while we
migrate between secrets management.

`forgeops rotate -n my_ns ds-env-secrets`

#### secret-agent

For secret-agent deployments, this involves editing `forgerock-sac` and
removing the 4 secrets.  You can use `kubectl edit -n my_ns sac forgerock-sac`
and deleting those 4 secrets from the config.

#### secret-generator

For a secret-generator deployment, you can just delete those 4 secrets.

`kubectl delete secret -n my_ns <SECRET_NAME>`

#### Add new secrets

Now we need to add the new secrets to our environment. Refer to the
documentation above on where to add your secrets.

#### Deploy new secrets

Now we need to deploy the new secrets, and make sure that the
`ds-set-passwords` job runs.

You need to force the `ds-set-passwords` job to run because by default it only
runs on initial deployment. Make sure this is in your environment's
`values.yaml`.

```
ds_set_passwords:
  force: true
```

Then you can run `helm upgrade` on your deployment to create the new secrets,
and rotate the `ds-env-secrets` secret.

```
helm upgrade -i identity-platform identity-platform \
  --repo https://ForgeRock.github.io/forgeops --version 2025.2.1 \
  -f helm/my_env/values.yaml -n my_ns
```

Make sure AM restarts so it starts using the newly created password. If `helm
upgrade` doesn't restart AM, you can do:

`kubectl rollout restart deployment am`

### Phase 2

In this phase, we'll bring in the rest of our secrets and end up entirely on
the new secrets provider.

#### Create old-ds-passwords secret

Now we run `forgeops rotate` on the `ds-passwords` secret so IDM maintains
connectivity while the passwords change.

`forgeops rotate -n my_ns ds-passwords`

#### Delete remaining secrets

Now we need to delete the remaining secrets.

##### secret-agent

For secret-agent we can just delete the `forgerock-sac` resource.

`kubectl delete -n my_ns sac forgerock-sac`

##### secret-generator

The secret-generator secrets can just be deleted with kubectl.

`kubectl delete secret -n my_ns keystore-create ds-passwords idm-env-secrets`

#### Disable ds-set-passwords

Edit `helm/my_env/values.yaml` and disable the ds-set-passwords job.

```
ds_set_passwords:
  force: false
```

#### Add remaining secrets

Replace the config for the remaining secrets (`keystore_create`,
`ds_passwords`, and `idm_env_secrets`). This is just like the "Add new secrets"
section above.

Update `helm/my_env/values.yaml` with the remaining secrets, and deploy the
helm chart with `helm upgrade`.

```
helm upgrade -i identity-platform identity-platform \
  --repo https://ForgeRock.github.io/forgeops --version 2025.2.1 \
  -f helm/my_env/values.yaml -n my_ns
```

#### Restart DS

We need to restart the DS pods so they get their new password.

`kubectl rollout restart -n my_ns sts ds-idrepo ds-cts`

#### Restart IDM

This is usually only needed for Kustomize. The `helm upgrade` command should
restart IDM because the `ds-passwords` secret changes. If it doesn't, you can
run this command.

`kubectl rollout restart deployment idm`

Once all pods are up and running, you are now operating on your custom secrets provider.

### Phase 3

This is the clean up phase of the migration. We want to remove the old
passwords so they can no longer be used.

#### Delete old-* secrets

First, we need to delete the old secrets.

`kubectl delete secret -n my_ns old-ds-env-secrets old-ds-passowrds`

#### Restart services

We need to restart the services and make sure the ds-set-passwords job runs.
You can do this by enabling the ds-set-passwords job and running `helm
upgrade`. Do this as you have done during this migration.  Remember to disable
the ds-set-passwords job if you want. It's only needed when doing password
rotations of `ds-env-secrets`.

The `helm upgrade` command should restart the ds pods and run the
`ds-set-passwords` job. If the pods don't restart, then do so with `kubectl
rollout restart`.
