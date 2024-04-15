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
$ helm upgrade identity-platform \
    oci://us-docker.pkg.dev/forgeops-public/charts/identity-platform \
    --version 7.5 --namespace identity-platform --install \
    -f values-override.yaml
```

The above example installs version `7.5` of the Helm chart from the repository.

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

