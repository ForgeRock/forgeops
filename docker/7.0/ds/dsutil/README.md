# dsutil

Deploys the DS tools and sample scripts. Utility scripts are placed in /opt/opendj/bin.

## Building

gcloud builds submit .

## Running

```
kubectl run -it dsutil --image=gcr.io/forgeops-public/ds-util --restart=Never -- bash
```

You can create a shell alias for the above the command:

alias fdebug='kubectl run -it dsutil --image=gcr.io/forgeops-public/ds-util --restart=Never -- bash'
