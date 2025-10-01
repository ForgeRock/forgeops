# Using Custom Secrets with ForgeOps

## Introduction

As of 2025.2.1, you can define custom secrets in your ForgeOps environments
with the new secret-generator functionality.  You can add extra secrets or you
can replace the default secrets provisioned by ForgeOps. This allows you
flexibility in your deployments based on the needs of your security policy.

This is primarily a Helm change as Kustomize users can just add patches to
their environment's overlay. There is a section with guidance on crafting those
patches.

## How the new secrets work

When you set `platform.secrets_enabled` to `true`, it enables the
`platform-secrets.yaml` template in the Helm chart which reads
`platform.secrets` in your values.yaml. This gets populated with our defaults
when you enable `secret-generator` with `forgeops env`.

Please note that the `platform-secrets.yaml` template replaces `_` with `-` in
secret names. So `ds_env_secrets` in `values.yaml` creates a secret named
`ds-env-secrets`.

### Secret Generator

All of our default secrets are created with `secret-generator`. The secrets
that have an `autogenerate` annotation get handled as a secret-generator
secret. The annotations for those secrets have
`secret-generator.v1.mittwald.de/` prepended. The `amster` secret is the only
one that doesn't use the `autogenerate` annotation so we add
`secret-generator.v1.mittwald.de/` to the type annotation to make sure it's
handled properly.

You can just add your own secret-generator owned secret by creating a new entry
in the dictionary and providing the appropriate annotations. You can see the
documentation on using secret-generator
[https://github.com/mittwald/kubernetes-secret-generator|here].

### Alternate secrets provider

If you want to use an alternate secrets provider, then you can do that as well.
You'll need to make sure you have the prerequisites installed for your chosen
provider before deploying.  If you want to change from `secret-generator` to an
alternative provider, then that is a migration and you should refer to that
section below.

The `platform.secrets` dictionary has the attributes of the various secrets
needed for a ForgeOps deployment. For example, the `amster_env_secrets` looks
like this:

```
    amster_env_secrets:
      annotations:
        length: 24
        autogenerate:
        - IDM_PROVISIONING_CLIENT_SECRET
        - IDM_RS_CLIENT_SECRET
```

This tells us that the secret `amster-env-secrets` contains two secrets
(IDM_PROVISIONING_CLIENT_SECRET and IDM_RS_CLIENT_SECRET) that are text strings
24 characters long.

The amster secret is the only secret-generator secret that doesn't use
`autogenerate` which is why we put the full annotation in there. This is an
example of how you can craft your own secrets to use alternate providers.

```
amster:
  annotations:
    secret-generator.v1.mittwald.de/type: ssh-keypair
```

It's recommended to do a single instance deployment and investigate the secrets
that get deployed so you can compare against the secrets you create via your
alternate method.

It's also recommended to create your own dir in kustomize/base and in a custom
default overlay if you use Kustomize. This allows you to use your custom secret
method from the start in new environments. You can use `--source|-s` with
`forgeops env` to specify which overlay to use as the default. You can set it
for your team by setting `SOURCE=my_default` in your
`$FORGEOPS_DATA/forgeops.conf`.

For a custom setup like this it is advised to setup a separate repo to hold
your ForgeOps data. See the production-workflow how-to for details on setting
one up for your team.

## Enabling custom secrets

To enable custom secrets for a fresh deployment, you can use the `forgeops env` command.

`forgeops env -e MY_ENV --secret-generator -f iam.example.com --cluster-issuer MY_ISSUER -n MY_NS`

If you are coming from 2025.2.0 on secret-generator, then you are fine and the
only thing you need to do is run `forgeops upgrade -e MY_ENV`. This handles the
change of `platform.secret_generator_enable` to `platform.secrets_enabled`.

If you have already created an environment, but not yet deployed it, then you can just enable it.

`forgeops env -e MY_ENV --secret-generator -n MY_NS`

If you have deployed but haven't gone live with it, you can reinstall your deployment.

```
forgeops env --env-name MY_ENV --secret-generator -n MY_NS`
helm uninstall identity-platform -n MY_NS
helm upgrade -i identity-platform identity-platform --repo https://ForgeRock.github.io/forgeops --version 2025.2.1 -f helm/MY_ENV/values.yaml
```

Your DS data will be on PVCs that are not destroyed by `helm uninstall`, and
your newly deployed DS pods will connect to those PVCs with your data.

For an existing deployment that is in production, you'll need to migrate from
secret-agent which is an involved process. This will be described in more
detail in its own section.

### Helm

In the helm chart, you can add your secret to the `platform.secrets` list. You
can then use custom env configurations to map them into your pods.

First let's create a normal secret-generator secret with a couple of random
strings that are 26 characters long.

```
platform:
  secrets:
    my_secret:
      annotations:
        length: 26
        autogenerate:
          - MY_SECRET_DATA_1
          - MY_SECRET_DATA_2
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

### Kustomize

For Kustomize users, you can just add the needed secrets to the secrets
overlay, and update the resource patches for the desired resources. To achieve
the Helm example in Kustomize you could do the following.

You can add new secrets by creating a new patch file in
`kustomize/overlay/my_env/secrets/secret-generator/my_secrets.yaml` with the
resource definitions for your secret.

```
---
apiVersion: v1
kind: Secret
metadata:
  name: my-secret
  labels:
  annotations:
    secret-generator.v1.mittwald.de/autogenerate: "MY_SECRET_DATA_1,MY_SECRET_DATA_2"
    secret-generator.v1.mittwald.de/length: "32"
```

To map the secret to an ENV variable, you need to edit the resource definition.
For AM, IDM, and IG the resource file is called `deployment.yaml` and for DS
it's `sts.yaml`. You can add it to the container definition there.

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: am
spec:
  replicas: 1
  template:
    spec:
      containers:
      - name: openam
        resources: {}
        envFrom:
          - secretRef:
              name: my-secret
```

You can apply your overlay, and the secret will be available as an ENV var.

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
documentation above on where to add your secrets based on if you are doing a
Helm or Kustomize deployment. In this case, we are replacing or updating the
config (Helm vs Kustomize) of the default secrets that ship with ForgeOps.

For Kustomize, it's recommended to add a new directory to
`kustomize/overlay/my_env/secrets` to keep your secrets. As part of Phase 2,
you will edit the `kustomization.yaml` in the secrets sub-overlay to point at
your custom secrets. In this example, we'll refer to
`kustomize/overlay/my_env/secrets/custom`. It's setup like any other Kustomize
overlay so it should have at minimum a `kustomization.yaml` and a file or files
to put your secret resources in.

#### Deploy new secrets

Now we need to deploy the new secrets, and make sure that the
`ds-set-passwords` job runs.

##### Helm

For Helm deployments, you need to force the `ds-set-passwords` job to run
because by default it only runs on initial deployment. Make sure this is in
your environment's `values.yaml`.

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

##### Kustomize

For Kustomize deployments, you don't need to apply the entire overlay. You can
just apply the new secrets, and then the ds-set-passwords sub-overlay. Here is
an example with the new secrets in `kustomize/overlay/my_env/secrets/custom`.

```
kubectl apply -k kustomize/overlay/my_env/secrets/custom
kubectl apply -k kustomize/overlay/my_env/ds-set-passwords
kubectl rollout restart deployment am
```

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

This is only for Helm deployments. Edit `helm/my_env/values.yaml` and disable
the ds-set-passwords job.

```
ds_set_passwords:
  force: false
```

#### Add remaining secrets

Replace the secret-generator config for the remaining secrets
(`keystore_create`, `ds_passwords`, and `idm_env_secrets`). This is just like
the "Add new secrets" section above.

##### Helm

Update `helm/my_env/values.yaml` with the remaining secrets, and deploy the
helm chart with `helm upgrade`.

```
helm upgrade -i identity-platform identity-platform \
  --repo https://ForgeRock.github.io/forgeops --version 2025.2.1 \
  -f helm/my_env/values.yaml -n my_ns
```

##### Kustomize

Add the remaining secrets into your `kustomize/overlay/my_env/secrets/custom` dir.

Now we need to change the secrets sub-overlay to point to your new secrets dir.
Edit `kustomize/overlay/my_env/secrets/kustomization.yaml` and change the
`resources` to point at `./custom` instead of `./secret-generator` or `./secret-agent`.

Now you can apply the secrets overlay, and it will bring in the remaining secrets.

`kubectl apply -k kustomize/overlay/my_env/secrets`

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

##### Helm

For Helm deployments, you can do this by enabling the ds-set-passwords job and
running `helm upgrade`. Do this as you have done during this migration.
Remember to disable the ds-set-passwords job if you want. It's only needed when
doing password rotations of `ds-env-secrets`.

The `helm upgrade` command should restart the ds pods and run the
`ds-set-passwords` job. If the pods don't restart, then do so with `kubectl
rollout restart`.

##### Kustomize

For Kustomize deployments, you need to restart the DS pods and run
`ds-set-passwords`.

```
kubectl rollout restart sts ds-cts ds-idrepo
kubectl apply -k kustomize/overlay/my_env/ds-set-passwords
```
