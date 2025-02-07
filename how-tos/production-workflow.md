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

### Setup your git repos

There are two different ways you can setup your git repo(s). The new and
recommended method is to setup a custom ForgeOps root. The old method is to
create a fork of the official ForgeOps repo.

#### Setup a custom ForgeOps root (Recommended)

This step is not mandatory, but it is recommended for production setups. There
are a few advantages to setting up your own root dir.

* Avoid git merge conflicts with a separate git repo
* Able to checkout forgeops version tags into branches to easily switch between versions of forgeops
* Much easier to see what is data vs code

In this example, we will create a new folder in `~/git`, and set it up as a
ForgeOps root. We'll also use 2025.1.1 as the version of ForgeOps we want to
use.

```
cd ~/git
mkdir forgeops_root
git clone -b main https://github.com/ForgeRock/forgeops.git
cd forgeops
git switch -c 2025.1.1
cd ..
cp -r forgeops/{kustomize,helm,docker} forgeops_root
cp forgeops/forgeops.conf.example forgeops_root/forgeops.conf
cat 'FORGEOPS_ROOT=${HOME}/git/forgeops_root' > ~/.forgeops.conf
cd forgeops_root
git init
git remote add origin https://github.com/MyOrg/forgeops_root
git add .
git commit -a -m 'Initial commit with defaults from forgeops'
git push
```

Now your ForgeOps is configured to use `~/git/forgeops_root` as the source of
your ForgeOps artifacts. This can now be used by your team. All they need to do
is clone both repos, select a ForgeOps version, and create a `~/.forgeops.conf`
that defines `FORGEOPS_ROOT`.

##### Setup forgeops.conf

The `forgeops.conf` file in `forgeops_root` can be populated with team-wide
values so no one has to remember to configure or use them. The file is fully
commented out to start with, and contains the defaults for the different
settings in the scripts. You can set the different values as needed. These
settings can be overridden at runtime by providing the appropriate flag.

For example, you can set `PUSH_TO` here, and not have to remember to set it
with `--push-to` when calling `forgeops build`. However, if you need to push
somewhere else as a special case, you can provide `--push-to` and the build
command will use it for that run.

Please note that it is possible to disable Helm or Kustomize with the `NO_HELM`
or `NO_KUSTOMIZE` variables. However, it's best to keep them in sync for a
couple of reasons. First, for Helm users, the `forgeops amster` command uses
Kustomize to work with resources on the cluster. If you plan on using that
command, it will need to be able to use the Kustomize overlay for your
environments. For Kustomize users, having the Helm environment allows you to
migrate to Helm as it is now the recommended method for deploying ForgeOps.

##### Create a ForgeOps Fork

The old method for working with ForgeOps was to fork the repo in your
organization's private git service (GitHub or otherwise). In this fork you'd
create one or more branches that your team works out of, leaving the main
branch unmodified. All of your organization's artifacts are stored inside this
fork, and you'll need to deal with merges as new ForgeOps versions are
released.

In this example, we are going to have a prod branch that contains your
configuration, and will be the branch you create your feature branches from.
We'll also be using 2025.1.1 as the ForgeOps version.

Prior to executing these commands, create a fork of
https://github.com/ForgeRock/forgeops.git. In this example, we will be using
https://github.com/MyOrg/forgeops as our fork.

```
mkdir ~/git
cd ~/git
git clone -b https://github.com/MyOrg/forgeops.git
cd forgeops
git switch -c prod 2025.1.1
git push -u origin prod
```

Now you have a fork, and a prod branch based on the 2025.1.1 tag. From here you
can create a new feature branch for creating your first environment.

#### Create a feature branch

It's best practice to work in a feature branch, so we'll create one in the repo
where our artifacts are stored. Whether that's in our custom ForgeOps root or
our ForgeOps fork.

`git switch -c first_env`

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

### Commit your changes to git

At this point, you should make sure all of the changes you made are committed to
git, and you can create a pull request (PR) into the prod branch.

```
git add .
git commit -a -m 'Adding initial stage configuration'
git push
```

Now you can follow your team's procedures for merging your `first_env` branch
into the `prod` branch.

## Selecting dev images

The image command can be used to select development container images that are
regularly built from the most recent development work from the product teams.

Select images for builds:

`./bin/forgeops image --release dev --release-name dev platform`

Select images for deployment in an environment:

`./bin/forgeops image --release dev --env-name test platform`

From here you can configure, build, and deploy as described above.
