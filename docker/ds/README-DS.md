# DS Customization and Utilities

## Directory Folders

* common: common scripts used to build multiple images
* cts:  DS image purpose built for CTS
* ds-idrepo: Purpose built for DS shared repo for AM/IDM. Also includes a cts backend for small installations
* proxy: DS proxy server. Experimental / unsupported.
* dsutil:  Utlility image that can ne run in a pod to perform various DS related tasks. Has all the ds tools installed.
* ds - Generic DS image- used by the ds-operator. This image is a fully "mutable" VM like image to run the directory. All state (including schema) is
 maintained on the runtime PVC claim. Configuration is performed at _runtime_.  See the [DS Operator](https://github.com/ForgeRock/ds-operator) for more details.
 Also see [ds/README.md](ds/README.md).

## Utility image (`dsutil`)

The `dsutil` image provides a bash shell into a pod that has all the DS tools
installed. Utility scripts are located in the `/opt/opendj/bin` directory.

To build the `dsutil` image:

```
gcloud builds submit .
```

To run the `dsutil` image:

```
kubectl run -it dsutil --image=gcr.io/forgeops-public/ds-util --restart=Never -- bash
```

To create a shell alias for the above command:

```
alias fdebug='kubectl run -it dsutil --image=gcr.io/forgeops-public/ds-util --restart=Never -- bash'
```