# Development Configurations using Skaffold and Kustomize

NOTE: This is a work in progress, For the 7.0.0 release, this folder will contain one or more platform samples.

These skaffold and kustomize artifacts in this folder provide an environment for
rapid and iterative development of configurations.  `skaffold dev` is used during development,
and will continually redeploy changes as they are made.

When assets are ready to be tested in QA or production, `skaffold run` is used to deploy the configurations.
Typically this will be a CD process triggered from a git commit or pull request.

## Limitations - READ THIS

* Currently this is aimed at iterative development - not a production deployment.
* AM file based configuration is a work in progress. See docker/am-fbc/README.md

## SETUP - READ THIS FIRST

* Install [skaffold](https://skaffold-latest.firebaseapp.com/) and [kustomize](https://kustomize.io/)
* Install cert-manager:  `3rdparty/cert-manager.sh`
* Add an entry in /etc/hosts for `default.iam.example.com` that points to your ingress ip (`minikube ip`, for example)

## Quick Start - minikube

When starting minikube, make sure it gets enough memory. For example:
`minikube start --memory=8192 --disk-size=30g --vm-driver=virtualbox --bootstrapper kubeadm --kubernetes-version=v1.13.2`

After starting minikube for the first time, enable the built-in ingress controller plugin:
`minikube addons enable ingress`

Each time you start minikube, enable the workaround for the bug in loopback networking,
and point docker at your minikube daemon:
```
minikube ssh "sudo ip link set docker0 promisc on"
eval $(minikube docker-env)
```

Make sure your namespace is set to `default`: `kubens default`

Run the following command in this directory:

`skaffold dev`

This will bring up AM, IDM and the idrepo (DS). Open https://default.iam.example.com/am in your browser. AM will
protect IDM. You can access the IDM admin console at: https://default.iam.example.com/admin/

## Quick Start - GKE using default.iam.forgeops.com

Run:

`skaffold dev -p dev --default-repo gcr.io/engineering-devops`

Setting the default repo tells skaffold to tag and push the images to that destination repo. This
repo must be accessible to your cluster. Skaffold
 also updates the image and tags in the kustomize deployment.

## Setting your skaffold default repo

If you want to omit the --default-repo flag for specific kubectl contexts, you can set up defaults on a per context basis:

`skaffold config set default-repo gcr.io/engineering-devops -k eng`

Will set the default repo for the kubectl context `eng`. You can now omit the --default repo on subsequent runs:

`skaffold -p dev`

Note that if you are submitting skaffold runs via a CD process, you should explicity set the default-repo via the command line.

## Kustomizing the deployment

Create a copy of one of the environments. Example:

```
cd kustomize/env
cp -r dev test-gke
```

* Using a text editor, or sed, change all the occurences of the FQDN to your desired target FQDN.
  Example, change `default.iam.forgeops.com` to `test.iam.forgeops.com`
* Update the DOMAIN in platform-config.yaml to the proper cookie domain for AM.
* Update the cert manager certificate request to use your Issuer. You can use the ca issuer for testing.
* Update kustomization.yaml with your desired target namespace (example: `test`). The namespace must be the same as the FQDN prefix.
* Copy skaffold.yaml to skaffold-dev.yaml. This file is in .gitignore so it does not get checked in or overlayed on a git checkout.
* In skaffold-dev.yaml, edit the `path` for kustomize to point to your new environment folder (example: `kustomize/env/test-gke`).
* Run your new configuration:  `skaffold dev -f skaffold-dev.yaml [--default-repo gcr.io/your-default-repo]`
* Warning: The AM install and config utility parameterizes the FQDN - but you may need to fix up other configurations in
IDM, IG, end user UI, etc. This is a WIP.

## Cleaning up

`skaffold delete` or `skaffold delete -f skaffold-dev.yaml`

If you want to delete the persistent volumes for the directory:

`kubectl delete pvc --all`

## Continuous Deployment

The file `../cloudbuild.yaml` is a sample [Google Cloud Builder](https://cloud.google.com/cloud-build/) project
that performs a continuous deployment to a running GKE cluster. Until AM file based configuration supports upgrade,
the deployment is done fresh each time.

The deployment is triggered from a `git commit` to [forgeops](https://github.com/ForgeRock/forgeops). See the
documentation on [automated build triggers](https://cloud.google.com/cloud-build/docs/running-builds/automate-builds) for more information.  You can also manually submit a build using:

```bash
cd forgeops
gcloud builds submit
```

Track the build progress in the [GCP console](https://console.cloud.google.com/cloud-build/builds).

Once deployed, the following URLs are available:

* [Smoke test report](https://smoke.iam.forgeops.com/tests/latest.html)
* [Access Manager](https://smoke.iam.forgeops.com/am/XUI/#login/)
* [IDM admin console](https://smoke.iam.forgeops.com/admin/#dashboard/0)
* [End user UI](https://smoke.iam.forgeops.com/enduser/#/dashboard)

## TODO

* Create AM file based config process. See am-fbc/
* The fqdn needs to be updated in the various configurations. For now - use sed, etc. but we need to a good procedure for
   setting environmental parameters
