# dsadmin - Directory Service Administration Chart

At present this chart is optional and has limited functionality. In the future it may be extended with
additional capabilities to manage a number of directory server instances.


## Functions

* Creates a dsadmin deployment. This runs a pod with the directory server tools installed. The pod sleeps, waiting for you to exec into the it to run various commands (ldap-modify, etc.).
* Optionally creates a Persistent Volume (PV) and Persistent Volume claim (PVC) for an NFS server where backups will be stored. The ds/ helm chart can mount this volume for backup and restore.
* Optionally creates an archive process to send backup data to an AWS S3 or GCP GS bucket.


You need only a single instance of this chart, even if you many directory server deployments.


## PV / PVC creation

This chart creates a PVC claim for the backup volume that is backed by an NFS PV. Helm's delete policy has been set to keep the PV and PVC when the dsadmin release is deleted. On subsequent installs of dsadmin, you should set the option:

`--set createPVC=false` 

To avoid trying to re-creaate the PVC that already exists.  See the values.yaml file.

## GCS / S3 archival

By default archival to S3 or GCS is disabled. See values.yaml for the possible values settings. If enabled, 
this chart creates a sync cron job that periodically copies the contents of the bak/ shared PVC to a bucket. 
This is provided as a sample. You will need to adjust this to suit your environment. 
