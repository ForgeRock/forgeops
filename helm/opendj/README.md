# OpenDJ Helm chart

Deploy one or more ForgeRock Directory Server instances using Persistent disk claims
and StatefulSets. 

# Sample Usage

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
in your own custom.yaml to control the behavior of the deployment. The features described below
are all controlled by variables in values.yaml.

# Scaling and replication

To scale a deployment set the number of replicas in values.yaml, and enable the postSetupJob. See values.yaml
for the various options. Each node in the statefulset is a combined directory and replication server. 


# Backup

Backups can be scheduled using the directory servers cron facility. The backup job is configured as part
of the post installation job (see values.yaml for cron settings).  Each pod in the statefulset mounts a backup
persistent volume claim (PVC) on bak/. This PVC holds the contents of the backups. You must size this PVC according 
to the amount of backup data you wish to retain. Old backups must be purged manually.

There is also an option to
copy backup data to a Google Cloud Storage bucket (gcs). This is useful as a disaster recovery
strategy, or to move data from one environment to another (prod to QA, for example).

# Restore 

A backup can restored from the mounted backup PVC. This can be done manually by execing into the container and running
the bin/restore utility. A convenience script (restore.sh) is also provided in the scripts/ directory.

Optionally, a directory server instance can be initialized from a previous backup done to a GCS bucket. This can
be used in a disaster recovery scenario, or in development to load a previously exported data set.


# Backup verification

An optional Kubernetes cron job can be scheduled that will periodically attempt to restore the last backup to
a transient instance, and verify the data by doing an export-ldif.  


# Slack Notifications

A sample script (scripts/notify.sh) can be enabled to send event notifications to slack. You must create a 
slack webhook URL and set in values.yaml. Currently notifications occur after a full backup and after verification 
of a previous backup.


# Benchmarking 

If you are benchmarking on a cloud provider make sure you use an SSD storage class as the directory is very sensitive 
to disk performance.

