# Managing Ping Identity Platform images

ForgeOps has the ability to work with multiple versions of Ping Identity
Platform (PIP) images. This allows for more flexibility when doing upgrades of
the forgeops tool and PIP. This feature is supported for PIP 7.4 and newer. The
`forgeops image` command is designed to help you keep up to date with the latest
images available for your version of PIP.

*Advantages*
* Allows you to upgrade ForgeOps and PIP separately on your schedule.
* When upgrading, you create a new release and test it through your different environments.
* Manage a single git release branch instead of one per platform version
* Allows for supported container images that are regularly scanned for OS level security vulnerabilities

## Supported and Scanned images

We scan and publish our images tagged with {PIP_VERSION}-TIMESTAMP. After
testing, these tags are added to JSON files hosted by our release site
(releases.forgeops.com).  The index links to the different files for your
inspection.

## TLDR
You create your own collections of component versions, called releases, with this tool.

Site containing release files: http://releases.forgeops.com

### Select 7.5.1 for entire platform

#### Dockerfiles

Creates docker/COMPONENT/releases/7.5.1-${TIMESTAMP}. These files should be added to git.

`forgeops image --release 7.5.1 platform`

#### Helm values and image-defaulter

Updates helm/ENV/values.yaml and kustomize/overlay/ENV/image-defaulter/kustomization.yaml

`forgeops image --release 7.5.1 --env-name stage platform`

#### Config

`forgeops config export --release-name 7.5.1-${TIMESTAMP} --env-name stage-single --config-profile stage am`

#### Build

`forgeops build --release-name 7.5.1-${TIMESTAMP} --env-name stage --config-platform stage am`

### Select 7.5.1 for platform with a custom release name

Use a release name of your choosing. If the release exists, it will be overwritten. These files should be added to git.

#### Dockerfiles

`forgeops image --release 7.5.1 --release-name 7.5.1 platform`

#### Config

`forgeops config export --release-name 7.5.1 --env-name stage-single --config-profile stage am`

#### Build

`forgeops build --release-name 7.5.1 --env-name stage --config-profile stage am`

### Select development versions of the platform for early visibility into new features(unsupported)

`forgeops image --release dev --env-name dev platform`

### Copy images between environments

#### Stage to prod

`forgeops image --copy --env-name prod --source stage`

#### Single to prod

`forgeops image --copy --env-name prod --source prod-single`

## Release Process

As of the 2025.1.0 release of ForgeOps, the release process has changed to
allow you to select the PIP version you want. This allows you much more
flexibility when using ForgeOps in production scenarios.

## Managing a release

Your releases are created and updated with the `forgeops image` command. It
does this by managing files in the docker, kustomize, and helm folders. There
are a few different ways you can run it depending on what you want to do.

All components release a x.y.0 at the same time, but they only release as
needed after that. This means that you may run 7.5.0 and 7.5.1 at the same time
for different components. The image tool is designed to accomodate that by
looking backwards within x.y when a component hasn't released the requested
version. So if you request 7.5.1 and only DS has published that version, then
the rest of the images will be 7.5.0 and the release name will use 7.5.1. Just
be aware that the release name is just a name and doesn't limit what platform
versions that release is composed of.

### Meta-Components

We use some meta-components to make it easier for you when setting images.

* platform = AM, Amster, am-config-upgrader, IDM, DS, UI
* ui = admin-ui, end-user-ui, login-ui

### Dockerfiles

When you want to update the images you use when building configured images with
`forgeops build`, you run image without the `--env-name` flag. This will create
files in `docker/COMPONENT/releases` for the selected components. Usually, you
should be using platform, ui, or ig as your target component.

`forgeops image --release 7.5.1 platform`

This will create files in `docker/COMPONENT/releases` called `7.5.1-TIMESTAMP`.
Each component gets its own file, but they are all named the same to tie them
together as a single release. This file should be added to git so that the
whole team can use them and be on the same page.

These files contain two shell variables called REPO and TAG. These point at the
container repo and tag of the image that was selected. This file is used by
multiple other forgeops commands to keep the version aligned across the
workflow. It is important to note that the `forgeops build` command will turn
the content of this file into build args for the docker command. If you choose
to call docker build directly, you'll need to account for that.

You can specify a custom release name with `--release-name NAME`. This can be
anything that makes sense to your team. If you reuse a name, the tool will just
overwrite it. You can use git history to roll back.

It is recommended to just use the release version as the release name. We don't
do this by default out of extreme caution.

`forgeops image --release 7.5.1 --release-name 7.5.1 platform`

### Environment files

Each environment you create has both helm and kustomize files in `helm/` and
`kustomize/` respectively. The image command updates both of them at the same
time. Generally, you only need to use `forgeops image` to select images in an
environment during your initial ForgeOps deployment. After that, your images
will use your baked in configuration, and the `forgeops build` command calls
`forgeops image` to update your environments. You use this to get an
unconfigured single instance ForgeOps deployment so that you can develop your
custom configuration and journeys.

`forgeops image --release 7.5.1 --env-name stage-single platform`

However, since the UI images do not need to be built, you will need to upgrade
them in your environment.

`forgeops image --release 7.5.1 --env-name stage-single ui`

### IG

IG is a standalone product intended to be deployed on remote networks that need
to talk to the platform. It also has a different versioning scheme.

*Dockerfiles*

`forgeops image --release 2024.12.2 --release-name 2024.12.2 ig`

*Environment Files*

`forgeops image --release 2024.12.2 --env-name ig-dfw ig`

*Build*

`forgeops build --release-name 2024.12.2 --config-profile dfw --env-name ig-dfw ig`

### Specific tag

If there is a specific tag you want to use for a component, then you can
specify it with `--tag`. You can see the list of published tags for each
version at the release web site (http://releases.forgeops.com).

`forgeops image --release 7.5.0 --release-name 7.5.1 --tag 7.5.0-202412031032 idm`

### Rolling back

All files managed by the image tool should be added to git to allow for team
collaboration as well as the ability to rollback to a previous version. Be
aware that there are challenges with rolling back DS, and this tool does not
solve those challenges. Refer to the DS docs or reach out to support when
rolling back DS to understand and manage potential data loss.

## Copying files between environments

Whether you use the same images across environments or not, you probably want
to copy images between environments instead of building the same image over and
over. This is where the `--copy` flag can help.

If you use the same config in your dev, test and production environments, then you
can use this to promote images through as part of your release process.

`forgeops image --copy --source dev --env-name test`

`forgeops image --copy --source test --env-name prod`

This will copy the images from the dev environment to the test environment,
then from test to prod. This allows you to test between, and then promote to the
next level in the process.  You can confirm this by comparing the helm values
files or the kustomize image-defaulter files.

If your environments have individual configurations, then we recommend using
`-single` environments to develop the config. You then promote from the single
to the actual environment.

`forgeops image --copy --source stage-single --env-name stage`

`forgeops image --copy --source prod-single --env-name prod`

## Advanced

### Individual Components

Sometimes, you may not want a specific component to be at the version you
requested. Maybe you want 7.5.1 for DS, but that AM version has a bug that
affects you. First create the 7.5.1 release for the whole platform.

`forgeops image --release 7.5.1 --release-name 7.5.1 platform`

Then you select 7.5.0 just for AM for the same release name.

`forgeops image --release 7.5.0 --release-name 7.5.1 am`

### Alternate release files

If your policy requires you to build your own container images from scratch,
you can create your own release files and host them on your own web site or
local file system.

#### Getting release files

In order to get started with your own set of release files, it's a good idea to
use the official files as a starting point. The main index page for
http://releases.forgeops.com has a list of all of the JSON files hosted there.
You should download each of them. They each contain a map that has a key called
'releases'. Like so:

idm.json:
```
{
  "releases": {
    "8.0": {
      "8.0.0": {
        "tags": [
          "8.0.0",
          "8.0.0-latest"
        ]
      },
      "scan": "weekly"
    }
  }
}
```

The top level release is a major.minor release, and it contains all of the
major.minor.patch releases as well as a scan key that tells our scanning
pipeline how often it should scan and patch our images for OS vulnerabilities.
The scan key is used by `forgeops info` to know what releases are supported,
and it is recommended to set it to something other than 'none'. The
major.minor.patch maps contain a tags array that lists all of the image tags
for that component.

#### Populate release files with custom images

You should remove versions that you don't need from the map, and modify the
ones you do use. For these versions, you should update the tags list to contain
the image tags of your images. We recommend beginning your tags with the official
x.y.z version so that the `forgeops info` command can parse the version from
the tag to help you see newer versions.

#### Host custom release files

After you've populated your custom release files, then you need to host them.
You can create your own website, or host them on your filesystem. If you want
to store them on the filesystem, it's recommended that you do so in a shared
ForgeOps Root so the entire team has access to the same files.

##### HTTP

*Dockerfiles*

`forgeops image --image-repo my-base-image-repo --releases-src http://pip-releases.example.com --release 7.5.1 platform`

*Environment files*

`forgeops image --image-repo my-image-repo --releases-src http://pip-releases.example.com --release 7.5.1 --env-name stage platform`

##### Filesystem

*Relative to forgeops root*

`forgeops image --image-repo my-base-image-repo --releases-src releases  --release 7.5.1 platform`

*Absolute*

`forgeops image --image-repo my-base-image-repo --releases-src $HOME/git/pip-releases --release 7.5.1 platform`

#### Update forgeops.conf to use custom releases source

While you can override the releases source with flags, it's much easier and
more consistent to set these in your team's forgeops.conf file.  In the bottom
of `forgeops.conf.example` there is a section on Releases. You'll need to
define RELEASES_SRC and BASE_REPO at a minimum to use your images. The
`forgeops build` command will update your Kustomize overlay and Helm values
with your PUSH_TO repo. The DEPLOY_REPO sets the container registry for
ForgeOps prepped images that don't have configuration baked in. If you intend
to provide your file based configs via ConfigMap instead of baking it into the
images, you'll want to set this as well.

*HTTP source*

`RELEASES_SRC=http://pip-releases.example.com`

*Filesystem source*

In this example, we assume you created a releases folder in your FORGEOPS_ROOT location.

`RELEASES_SRC=releases`

The BASE_REPO should be set to the container repository that you push your base
images to.

`BASE_REPO=us-docker.pkg.dev/MY_ORG/forgeops-base-images`

Commit and push these changes to your FORGEOPS_ROOT git repo to make them
available to your entire team and your automation.

#### Viewing new official versions

After you switch your forgeops.conf over to using your custom release files,
you may want to see what images are officially available. To do this, you can
comment out RELEASES_SRC and BASE_REPO in your forgeops.conf, and run the
`forgeops info` and `forgeops image` commands normally. You can also use
`--releases-src` and/or `--image-repo` with the `forgeops info` and `forgeops
image` commands to point to the official locations. You can find the current
defaults by looking in `lib/python/defaults.py`.

`forgeops info --releases-src http://releases.forgeops.com --list-releases`

If you want to play with the official images, you can use the `forgeops image` command to do so.

*Update Dockerfiles*

`forgeops image --releases-src http://releases.forgeops.com --image-repo us-docker.pkg.dev/forgeops-public/images-base --release 8.0.1 platform`

*Update Helm/Kustomize*

`forgeops image --releases-src http://releases.forgeops.com --image-repo us-docker.pkg.dev/forgeops-public/images --release 8.0.1 platform`
