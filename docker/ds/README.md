# ds - ForgeRock Directory Service Docker Image


## Build

This Dockerfile uses a multi-stage docker build to create a final docker image. The first stage creates a 
prototype image that is then copied to the second stage to create the final docker image. 

Stage 1 scripts are in the bootstrap/ folder. This folder is not copied into the final docker image. At a high level stage 1
does the following:

* Creates two ds instances that are replicated to each other. The instances have hard coded hostnames (ds1.example.com).
* Two backends are configured (ou=tokens, dc=data) making the instance suitable for a CTS and a userstore
* Required schema is loaded into each backend. See bootstrap/ldif/*
* Both instances are shut down
* The second instance is deleted
* The first instance configuration is modified to use commons confiugration expressions to replace the hard 
 coded values. For example, the hostname `ds1.example.com` is replaced with `&{fqdn}`. The idea is that 
 these values will be provided at runtime by the helm chart.

 At stage 2, the first instance configuration is copied in /opt/opendj - and becomes the final runtime instance.

Refer to the corresponing helm chart (helm/ds) to see how to deploy this docker image. It is essential to 
supply the appropriate environment variables in order for the intance to run correctly. 

## Docker-entrypoint

The image assumes that a persistent volume will be mounted on the /opt/opendj/data directory. This is where volatile
data lives - and persists across container restarts.

At runtime, the docker entry point looks to see if this directory is empty, and if it is, copies the initial backends (e.g. userstore, cts) to this volume
to use as starter databases.  If data exists in the pvc, the copy will not occur.

The file `env.sh` set a number of environment variables that are used to template out the config.ldif file. For example,
RS_SERVERS is a list of all the DS/RS hostnames and ports. 


## Limitations

The admin-backend and other LDIF backends currently do not use commons configuration. As a consequence some commands do not work correctly. `dsreplication status`,
for example, will not report the correct status.

The directories internal metrics (exposed via Prometheus) report accurate status and can be used for monitoring and alerting. In addition
the directory replication logs (logs/replication) show replication activity.

These limitations will be removed in the 6.5/7.0 time frame.

