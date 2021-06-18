# Kustomize

This folder provides Kustomize artifacts for deploying the ForgeRock Identity 
Platform.

If you are not familiar with Kustomize, please read the documents and study the 
tutorials [here](https://kustomize.io/) before you try to work with ForgeRock's 
Kustomize artifacts.

## Organization

The `kustomize/base` directory includes bases for the components of the 
ForgeRock Identity Platform - AM, IDM, DS, and IG. The `overlay` folder includes
the environments. Environments pull together the components into a Kustomize 
deployment. See the `kustomize/overlay/all` directory for an example.

## Reviewing Kustomize Output

Use the `kustomize build` command to see the ouput that Kustomize generates. For
example:

```bash
cd kustomize/overlay/all
# This will show you what is sent to the cluster
kustomize build
```

## Docker Images

The Docker images referenced in the Kustomize files are generic (for example, 
`am` or `ig`), and are not specific to a Docker registry (such as 
`gcr.io/forgerock-io/am-base:7.1.0`).

We can not directly deploy the generic images, because we need a Docker image
that has the configuration "baked in". This is where Skaffold comes in to the 
picture. Skaffold builds new Docker images that include configuration, and 
"fix up" the Docker image tags in Kustomize, replacing the generic names (`am`) 
with specific image names tagged with an SHA hash (for pre-release builds) or a 
Git hash (for release builds).

For more information, see the forgeops repository's [top-level README](../README.md).

## Further Discussion

The `kustomize` directory demonstrates a directory-based organization. You could
also use Git branching. For more information, see 
[this page](https://kubectl.docs.kubernetes.io/guides/app_deployment/diffing_local_and_remote_resources/).
