## Helm

Helm charts can be found under the `charts` directory.  Execute `helm --help`
for more information on executing Helm commands.

The `identity-platform` directory contains the identity-platform Helm chart.

### Identity platform configuration

When installing from a locally cloned Git repository, it is recommended that
one does not edit the default `values.yaml` as it is Git managed.  However, the
`values.yaml` file can be copied and then edited with desired configuration
updates.  e.g. `cp values.yaml values-override.yaml`

### Identity platform install

In order to deploy the identity platform, simply execute `helm` with the
desired options.  Example:

```bash
$ kubectl create namespace identity-platform
$ helm upgrade identity-platform identity-platform \
    --repo https://ForgeRock.github.io/forgeops/ \
    --version 2025.1.0 --namespace identity-platform --install \
    -f values-override.yaml
```

The above example installs version `2025.1.0` of the Helm chart from the
repository.

The next example will deploy the identity platform while using the command line
to set the host and TLS settings for the ingress:

```bash
$ kubectl create namespace identity-platform
$ helm upgrade identity-platform identity-platform \
    --repo https://ForgeRock.github.io/forgeops/ \
    --version 2025.1.0 --namespace identity-platform --install \
    --set platform.ingress.hosts={identity-platform.domain.local} \
    --set platform.ingress.tls.issuer.name=identity-platform-issuer \
    --set platform.ingress.tls.issuer.kind=Issuer \
    --set platform.ingress.tls.issuer.create.type=letsencrypt-prod \
    --set platform.ingress.tls.issuer.create.email=address@domain.com
```

The following example, when executed from the `charts/identity-platform`
directory, can be used to install from a locally cloned git repository:

```bash
$ kubectl create namespace identity-platform
$ helm upgrade identity-platform . \
    --namespace identity-platform --install -f values-override.yaml
```

### Identity platform uninstall

```bash
$ helm delete identity-platform -n identity-platform
```

