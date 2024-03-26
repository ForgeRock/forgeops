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
`gcr.io/forgerock-io/am-base:7.x.0`).

You can not directly deploy the generic images, because you need Docker images
that are rebuilt to work with forgeops. The `forgeops build` command builds new 
Docker images that include any customizations to the Docker iamge or custom product 
configuration, and sets up the Docker image tags in the [image defaulter](./deploy/image-defaulter/kustomization.yaml). 

For more information, see the forgeops repository's [top-level README](../README.md).

## Further Discussion

The `kustomize` directory demonstrates a directory-based organization. You could
also use Git branching. For more information, see 
[Diffing Local and Remote Resources](https://kubectl.docs.kubernetes.io/guides/app_deployment/diffing_local_and_remote_resources/)
in the Kubernetes documentation.
