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

To deploy Directory Proxy Server
`helm install --set "bootstrapType=proxy,djInstance=dps,runSetup=false" opendj`


# Values.yaml

Please refer to values.yaml. There are a number of variables you can set on the helm command line, or 
in your own custom.yaml that control the
behavior of the deployment. 

# Scaling and replication

To scale a deployment set the number of replicas, and enable the postSetupJob. See values.yaml
for the various options. Each node in the statefulset is a combined directory and replication server. 


# Backup 

Backups can be scheduled by the directory servers cron facility. The helm chart also has an option to
write backup data to a Google Cloud Storage bucket (gcs). See values.yaml.

If you are benchmarking on GKE, use an SSD storage class,
and keep in mind that PD IOPS scale based on the size of the volume.
Anecdotally, you need to allocate at least 50 GB to get equivalent
performance to a MacBook Pro with SSD.