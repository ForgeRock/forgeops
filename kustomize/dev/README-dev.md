# ForgeOps Developer Profile

_NOTE: This is work in progress. This is a preview of a developer-focused forgeops release._

The developer profile provides:

* **Reduced footprint deployment.**
  There is a single DS instance for the CTS and idrepo instead of multiple
  instances.
* **Developer Git server.**
  IDM and AM configurations are saved to an "emptyDir" volume, and then pushed
  to a Git server pod running in the developer's namespace. Any changes the
  developer makes in the AM and IDM UIs are be saved to Git.
* **Phased deployment.** The ForgeRock Identity Platform is deployed in phases
  rather than by using a one-step _skaffold run_ deployment. The phased
  deployment lets you iterate on development without needing to reload users or
  recreate secrets.

## Deployment Steps

1. Before deploying the platform, you must install the Secret Agent operator and
the ds-operator, a one time activity.

    To install the operators:

    ```
    bin/secret-agent.sh install
    bin/ds-operator.sh install
    ```

    (ForgeRock staff using the `eng-shared` cluster: these have already been
    installed.)


2. Modify the `kustomize/dev/dev-base/kustomization.yaml` file for your
   environment. Make sure that the FQDN and the CERT_ISSUER are set correctly.

3. Change your context to your namespace.

4. Run the `dev/start.sh` script.

## Passwords

Run the `bin/print-secrets.sh` script to obtain passwords for logging in to the
AM and IDM UIs.

## Running without an External UI

Modify the `kustomize/dev/dev-base/kustomization.yaml`  and comment out the `ui`
NGINX containers.

## Pulling Files From the Git Server

The Git server runs as a pod, and contains updates that you have made to the
AM and IDM configurations.

To pull these locally:

```
kubectl port-forward deployment/git-server 8080:8080

# In another shell
git clone http://git:forgerock@localhost:8080/fr-config.git
```

The AM updates are in the `am` branch, and the IDM updates are in the `idm`
branch.

## Iteration

To redeploy a single component use the `kubectl apply` command. For example, to
redeploy AM:

```
kustomize build am | kubectl apply -f -
```

## Deleting the Deployment

Run the `dev/nuke.sh` command to delete the deployment. Note that all
PVCs (including the git and ds persistence) are also removed.

If you just wish to scale down the pods, you can do

```
kubectl scale --replicas=0 deployment --all
```

And to resume

```
kubectl scale --replicas=1 deployment --all
```
