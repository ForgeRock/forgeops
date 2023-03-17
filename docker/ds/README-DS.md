# Directory Server (DS) Customization and Utilities

**NOTE**

The current production image is in the `ds-new` folder. This is the image used by the ds-operator.

The ds-cts and ds-idrepo are the pre 7.3.0 images - and here for reference.

## Directory Folders

* ds-new - Generic DS image used by the ds-operator or for fully "mutable" directory deployments. This is
the recommended DS image for new deployments.
* common: common scripts used to build multiple images
* cts:  Legacy DS image purpose-built for CTS. ** For internal purposes only **
* ds-idrepo: Legacy DS image purpose-built for DS as the shared repository for AM/IDM. Also includes a CTS backend for small installations. ** For internal purposes only **
* proxy: DS proxy server. Experimental / unsupported.
* dsutil:  Utility image that can be run in a pod to perform various DS related tasks. Has all the DS tools installed.

## Utility image (`dsutil`)

The `dsutil` image provides a bash shell into a pod that has all the DS utility scripts installed in the /opt/opendj/bin directory.

To build the `dsutil` image:

```
gcloud builds submit .
```

To run the `dsutil` image:

```
kubectl run -it dsutil --image=us-docker.pkg.dev/forgeops-public/images/ds-util --restart=Never -- bash
```

To create a shell alias for the above command:

```
alias fdebug='kubectl run -it dsutil --image=us-docker.pkg.dev/forgeops-public/images/ds-util --restart=Never -- bash'
```
