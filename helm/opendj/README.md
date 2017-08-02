# OpenDJ Helm chart

Deploy one or more OpenDJ instances using Persistent disk claims
and StatefulSets. 

# Usage

To deploy to a Kubernetes cluster:

`helm install --set "djInstance=userstore,numberSampleUsers=1000" opendj`

This will install a sample DJ userstore with 1000 users. 

The instance will be available in the cluster as userstore-0. 

If you wish to connect an ldap browser on your local machine to this instance, you can use:

`kubectl port-forward userstore-0 1389:1389`

And open up a connection to ldap://localhost:1389 

The default password is "password".


# Values.yaml

Please refer to values.yaml. There are a number of variables you can override to control the
behavior of the deployment. 

# Scaling and replication

To scale a deployment:

`kubectl scale --replicas=2` statefulset userstore


Each new DJ node will be configured 
to replicate to the first (master) node.  This is a very simple replication topology
that will only support a small number (say 3) of OpenDJ nodes. It
should be acceptable for testing and small installations. 

# Backup 

To enable DJ backups, set:

`enableGcloudBackups: true`

And create a gcs bucket for accepting the backup data:

`gsBucket: gs://forgeops/dj-backup `

This has only been tested on GKE.

# Notes


Currently the minikube hostpath provisioner creates PVC volumes owned by root. The DJ process
runs as user "forgerock", so this causes permission issues. The chart's values.yaml defaults to:

`djPersistence: false`

Which will use temporary volumes for DJ data. These will not survive minikube restarts or chart redeployment. On GKE
you can set this to true, as the GKE PVC provisioner creates volumes with the correct ownership.


If you are benchmarking on GKE, use an SSD storage class,
and keep in mind that PD IOPS scale based on the size of the volume.
Anecdotally, you need to allocate at least 50 GB to get equivalent
performance to a MacBook Pro with SSD.


