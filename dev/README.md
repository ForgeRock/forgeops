# Development Configurations using Skaffold and Kustomize

NOTE: This is a work in progress, For the 7.0.0 release, this folder will contain one or more platform samples.

These skaffold and kustomize artifacts in this folder provide an environment for
rapid and iterative development of configurations.  `skaffold dev` is used during development,
and will continually redeploy changes as they are made.

When assets are ready to be tested in QA or production, `skaffold run` is used to deploy the configurations.
Typically this will be a CD process triggered from a git commit or pull request.

## Limitations - READ THIS

* Currently this is aimed at iterative development - not a production deployment.
* The AM pod in non file based mode will come up fresh everytime - it will not retain its boot configuration
    This is because the boot.json and other bootstrap files are not mounted in the container. We are waiting for file based
    configuration to address this. See the comments in docker/am/Dockerfile.
* AM file based configuration is a work in progress. See docker/am-fbc/README.md
* The FQDN defaults to default.iam.forgeops.com. Work is in progress to make this more configurable.

## SETUP - READ THIS FIRST

* Install [skaffold](https://skaffold-latest.firebaseapp.com/) and [kustomize](https://kustomize.io/)
* Install cert-manager:  `3rdparty/cert-manager.sh`
* Add an entry in /etc/hosts for `default.iam.forgeoops.com` that points to your ingress ip (`minikube ip`, for example)
  This restriction on the FQDN will be updated shortly...

## Running skaffold

To run just IDM:

`skaffold dev -p idm`

To run just AM:

`skaffold dev -p am`

To run the "full stack" (currently does not start IG)

`skaffold dev`

## Cleaning up

`skaffold delete`

If you want to delete the persistent volumes:

`kubectl delete pvc --all`


## TODO

* Create AM file based config process. See am-fbc/
* If skaffold restarts, AM will go through configuration again with amster. Configurations do not persist. For development 
   this work OK, but we need to enable a persistent mode. 
* The fqdn needs to be updated in the various configurations. For now - use sed, etc. but we need to get a good procedure for
   setting environmental parameters
* Create "CDM" sizing configurations in kustomize/env

