# OpenDJ Helm chart

Deploy one or more ForgeRock Directory Server instances using Persistent disk claims
and StatefulSets. 

## Sample Usage

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


## Values.yaml

Please refer to values.yaml. There are a number of variables you can set on the helm command line, or 
in your own custom.yaml to control the behavior of the deployment. The features described below
are all controlled by variables in values.yaml.

## Diagnostics and Troubleshooting

Use kubectl exec to get a shell into the running container. For example:

`kubectl exec userstore-0 -c opendj -it bash`

There are a number of utility scripts found under `/opt/opendj/scripts`, as well as the 
directory server commands in `/opt/opendj/bin`.

use kubectl logs to see the pod logs. Note that init container logs can also be displayed by providing the
init container name:

`kubectl logs userstore-0 -c setup -f`

## Scaling and replication

To scale a deployment set the number of replicas in values.yaml. See values.yaml
for the various options. Each node in the statefulset is a combined directory and replication server. 


## Backup

Each pod in the statefulset mounts a shared backup
 volume claim (PVC) on bak/. This PVC holds the contents of the backups. You must size this PVC according 
to the amount of backup data you wish to retain. Old backups must be purged manually. The backup pvc must
be an ReadWriteMany volume type (like NFS, for example). You may wish to deploy the NFS provisioner chart
(see ../../bin/create-nfs-provisioner.sh for an example).

A backup can be initiated manually by execing into the image and running the scripts/backup.sh command. For example:

`kubectl exec userstore-0 -it bash`
`./scripts/backup.sh`

The backups can be listed using `scripts/list-backup.sh`

## Disaster Recovery

There is also an option to
copy backup data to a Google Cloud Storage bucket (gcs). This is useful as a disaster recovery
strategy, or to move data from one environment to another (prod to QA, for example). 

## Restore 

A backup can restored from the mounted backup PVC. This can be done manually by execing into the container and running
the bin/restore utility. A convenience script (restore.sh) is also provided in the scripts/ directory. 

Optionally, a directory server instance can be initialized from a previous backup done to a GCS bucket. This can
be used in a disaster recovery scenario, or in development to load a previously exported data set.


## Backup verification

An optional Kubernetes cron job can be scheduled that will periodically attempt to restore the last backup to
a transient instance, and verify the data by doing an export-ldif.  The conclusion of this job will
invoke the scripts/notify.sh script which currently sends a slack notification (see below).

Using Kubernetes tools, `kubectl get cronjob`  and `kubectl logs cron-job-xyz` can be used to introspect 
the results of the verification.


## Slack Notifications

A sample script (scripts/notify.sh) can be enabled to send event notifications to slack. You must create a 
slack webhook URL and set in values.yaml. Currently notifications occur after a full backup and after verification 
of a previous backup.

If you want to use an alternate notification mechanism you can replace the notify.sh script in the image 
with an alternate implementation.


## Benchmarking 

If you are benchmarking on a cloud provider make sure you use an SSD storage class as the directory is very sensitive 
to disk performance.

## Initializing a DS cluster from a previous backup (experimental)

Backups to gcs are placed in the a directory structure that looks like this:

`gs://backup-bucket/backup-root/{namespace}/{instance}/yy/mm/dd/`

For example:

`gs://forgeops/dj-backup/10m/sandbox/userstore/2018/05/31`

Where 'sandbox' is the namespace name, and 'userstore' is the instance.

The restore script will recurse through the `yy/mm/dd` to find the most recent backup. Within each day folder, there is a full backup and a a number of incrementals. The restore will restore the most recent incremental and full backup for that day.

To recover this backup to a new instance, perform the following procedure:

### Copy the data to a gcs location for the desired namespace

For example, if your namespace is `test` you can do the following:

`gsutil cp -r gs://forgeops/dj-backup/10m/sandbox gs://forgeops/dj-backup/10m/test`

### Prepare your custom.yaml

The custom.yaml for your new cluster will enable gcs restore parameters, and point at your restore bucket from above. For example:

```yaml
restore:
  enabled: true

gcs:
  # Set this to true to enable backups to Google Cloud Storage. You need to create the top level bucket first.
  restore: true
  # Restore bucket.
  restoreBucket: gs://forgeops/dj-backup/10m
```

Note that the `namespace` and `instance-name` are calculated, are *not* part of the restoreBucket path.

### Install your helm chart

Using the above custom.yaml (note that additional parameters may be required - the sample above shows only
the restore features), install your helm opendj chart. You should see the init containers run for `gcs`, `restore` and `setup`, before the final DS container runs. Using kubectl logs, you can view the output. For example:

`kubectl logs userstore-0 -c gcs -f`

Repeat the above for the restore and setup init containers. 

### Troubleshooting

If the gcs init container can not restore the contents to the bak/ folder, the path is incorrect, or your cluster does not have sufficient priviliege to read/write to a gcs storage bucket. Refer to the GKE documentation for more information. A possible quick fix is to create your cluster using:

 `--scopes "https://www.googleapis.com/auth/cloud-platform"`
