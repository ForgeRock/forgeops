# Production Workflow

## Introduction

The previous forgeops tool was not designed for production use, but instead was
intended to be used as an example of the resources necessary to get the Ping
Identity Platform (PIP) running in Kubernetes (k8s). The new tool was designed
for production use, and these instructions describe the intended setup and
workflow for production environments.

## Setup

Your system needs to be set up to run ForgeOps. Follow the instructions in
<a href="how-tos/laptop-setup.md">Laptop Setup</a> for details.

## Initial Workflow

This workflow is used when creating a new environment. It includes all of the
steps you'll use in other workflows plus some others. Therefore, we'll explain
the steps in detail here, and just provide commands for any other workflows.

### Create an environment

The first thing you do is use `forgeops env` to create an environment. You
need to provide an FQDN (--fqdn) and an environment name (--env-name).

Previously, we had t-shirt sized overlays called small, medium, and large. Now,
we just have `kustomize/overlay/default` which is a single instance overlay.
You can still use `--small`, `--medium`, and `--large` to configure your
overlay, and the env command will populate your environment with the size you
requested.

So if we want a medium sized stage deployment with an FQDN of iam.example.com,
we'd do this:

`./bin/forgeops env --fqdn stage.iam.example.com --medium --env-name stage`

We recommend creating a single-instance environment to go along with each
actual environment. This allows you to use the single to develop your file
based config, and build images with the config(s) for that environment.

`./bin/forgeops env --fqdn stage-single.iam.example.com --env-name stage-single`

You will find the environments in `kustomize/overlay/` and `helm/`. These need
to be added to git.

```
git add helm kustomize
git commit -m 'Adding stage env'
```

### Select a version of Ping Identity Platform (PIP)

The Forgeops tool now works with multiple versions of PIP so you'll need to
select which one you want to work with. For an initial environment setup,
you'll want to set the version for both builds and deployments. After
developing your initial config, you'll only need to update the UI images in
your environments..

See <a href="manage-platform-images.md">Manage Platform Images</a> for details.

#### Select PIP version for builds

In the build path (docker), there are folders for each component (am, idm, ds,
etc). The `forgeops image` command will create a folder called releases in each
of the component folders. This is where the image command will create and
update release files. This allows you create your own "releases".

`forgeops image --release 7.5.1 --release-name 7.5.1 platform`

These files should be added to git.

```
git add docker
git commit -m 'Adding new 7.5.1 release for builds'
```

#### Select PIP version for deployments

`forgeops image --release 7.5.1 --env-name stage-single platform`

### Apply single environment

For Helm, you can just supply the values file(s) to `helm install` or `helm upgrade`.

`helm upgrade -i identity-platform identity-platform --repo https://ForgeRock.github.io/forgeops/ -f helm/stage-single/values.yaml`

For Kustomize, you have two options. Running `kubectl apply -k
/path/to/forgops/kustomize/overlay/MY_OVERLAY` or using `forgeops apply`.

To apply the example from above, you'd do:

`./bin/forgeops apply --env-name stage-single`

### Configure your deployment

Now that you have a vanilla single-instance PIP deployment up and running, you
can start applying your AM and IDM configurations. These are your file-based
configurations (FBC).

### Build images for an environment

When you need to build a new application image, you can use `forgeops build`
to do that. It will apply the application config profile you requested from the
build dir (`docker/APP/config-profiles/PROFILE`), build the container image,
and push the image up to a registry if you tell it to. It will also update the
image-defaulter and values files for the targeted environment.

If we want to build new am and idm images for our stage environment using the
stage-cfg profile, we'd do this:

`./bin/forgeops build --env-name stage-single --config-profile stage-cfg --push-to "my.registry.com/my-repo/stage" am idm`

Once that is done, you'd apply the environment via Helm or Kustomize to deploy.

### Copy images from stage-single to stage

Now that you've developed and tested your configs, you can copy them over to the real deployment.

`forgeops copy --source stage-single --env-name stage`

### Apply the real deployment

#### Using Helm

`helm upgrade -i identity-platform identity-platform --repo https://ForgeRock.github.io/forgeops/ -f helm/stage/values.yaml`

#### Using Kustomize

##### kubectl

`kubectl apply -k /path/to/forgeops/kustomize/overlay/stage`

##### forgeops apply

`forgeops apply --env-name stage`

## Normal config workflow

After initial deployment, you will inevitably want to make a config change. You
just need the config, export, build, copy, and apply steps.

### Config change

Make your change(s) on your single instance environment.

Export that config change.

`forgeops config export am stage`

`forgeops config export idm stage`

### Build

Build your new images with your config.

`forgeops build -e stage-single -p stage am`

`forgeops build -e stage-single -p stage idm`

### Apply and test

Apply it to your single environment and test it.

#### Using Helm

`helm upgrade -i identity-platform identity-platform --repo https://ForgeRock.github.io/forgeops/ -f helm/stage-single/values.yaml`

#### Using Kustomize

##### kubectl

`kubectl apply -k kustomize/overlay/stage-single`

##### forgeops apply

`forgeops apply -e stage-single`

### Copy images from single

You can copy the tested images to your real environment.

`forgeops image --copy --env-name stage --source stage-single`

### Apply real environment

#### Using Helm

`helm upgrade -i identity-platform identity-platform --repo https://ForgeRock.github.io/forgeops/ -f helm/stage/values.yaml`

#### Using Kustomize

##### kubectl

`kubectl apply -k kustomize/overlay/stage`

##### forgeops apply

`forgeops apply --env-name stage`

## Selecting dev images

The image command can be used to select development container images that are
regularly built from the most recent development work from the product teams.

Select images for builds:

`./bin/forgeops image --release dev --release-name dev platform`

Select images for deployment in an environment:

`./bin/forgeops image --release dev --env-name test platform`

From here you can configure, build, and deploy as described above.
