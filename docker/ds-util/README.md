# Directory Server (DS) Utilities

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
