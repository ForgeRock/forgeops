# Development Configurations using Skaffold and Kustomize

NOTE: This is a work in progress, For the 7.0.0 release, this folder will contain one or more platform samples.

These skaffold and kustomize artifacts in this folder provide an environment for
rapid and iterative development of configurations.  `skaffold dev` is used during development,
and will continually redeploy changes as they are made. 

When assets are ready to be tested in QA or production, `skaffold run` is used to deploy the configurations.
Typically this will be a CD procerss triggered from a git commit or pull request.


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

