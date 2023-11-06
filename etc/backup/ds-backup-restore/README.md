# Directory Services Backup and Restore Using Snapshots

>CAUTION The DS Operator is deprecated and will be removed in a future release

The following samples are provided:

* [ds-backup-cron](ds-backup-cron) A cron task that backs up the directory on a schedule.
* [ds-backup-volume](ds-backup-volume) A job that does a one time backup of a DS volume.
* [ds-restore-volume](ds-restore-volume) A job that restores a backup to a PVC. The PVC can be used to initialize a cluster.

These samples are provided as is, and are not supported by ForgeRock. You will need to modify
these samples to suit your requirements.

## LDIF vs ds-backup

The samples can backup/restore using LDIF files (via ldif-import) or ds-backup format.

ds-backup format files are encrypted. The DS keystore secret must be available to back up or restore DS.

Edit the _job_.yaml file to choose ldif of ds-backup. The default is LDIF backup format.

## Prerequisties

* You must enable Kubernetes volume snapshots on your cluster and use the appropriate storage class. Consult
 your cloud provider's documentation.
* The directory server PVC must be a CSI storage class. On GKE, `premium-rwo` and `standard-rwo` are automatically
 created when the CSI driver is enabled.
* You must have a volume snapshot class defined. The default used in these examples is `ds-snapshot-class`.
* GKE has snapshot rate limits. Each disk can be snapshotted once every ten minutes. Watch for this
 if you perform frequent testing.


## Backup Cron Task

This sample Kubernetes cron job backs up the directory using volume snapshots.

The cron job works as follows:

* A recurring cron task calls `backup-base/scripts/snapshot.sh` to create a snapshot of the directory PVC. This
 snapshot is used to create a clone of the directory PVC.
* After creating the clone, the script launches a user supplied Kubernetes job `backup-base/scripts/job.yaml`.  This job is responsible
 for backing up the data in LDIF or DS backup format.  You will need to edit this job to suit
 your requirements.
* The backup job can further copy the backup files to an archival source. A sample using a GCS bucket is provided.
* It is important to ensure the backup has plenty of time to complete before the next cron task is run.
* Older snapshots are retained for a period of time. Edit the `purgeTime` variable in `backup-base/scripts/snapshots.sh` to set the purge delay.

This diagram visualizes the process:

![](ds-volume-backup.png)


 To modify the sample for your requirements:

 * Edit snapshot.sh. See the comments in the file, but minimally you will want to set the DS volume to snapshot/backup.
 * Edit ../backup-base/pvc.yaml to ensure the backup PVC has sufficient space to hold your backups.
 * Edit scripts/ds-backup.sh. You will want to choose the backup type (LDIF or DS backup). There is also an optional
 container that backs up to a GCS bucket. You can adapt this container for your environment.

## Adhoc Backup Job

[ds-backup-volume](ds-backup-volume) performs adhoc "one shot" backups.

You need to edit this example. The process is:

* Edit volume-snapshot.yaml. Take a snapshot of the desired directory service disk.
* The snapshot is used to create a clone `ds-data-clone` of the live data disk. The clone is
 the disk that is backed up.
* Edit the backup job paramaters and optional gsutil container.  Run the backup:

`kustomize build ds-backup-volume | kubectl apply -f -`

To rerun this job, first remove the existing job `kubectl delete job/ds-backup`.


## Restoring a Backup

The restore process in [ds-restore-volume](ds-restore-volume) is designed to restore the contents of the DS data to a snapshot. The snapshot is then used to reinitialize a DS cluster. This is done by setting the datasource for each DS PVC. For example:

```
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: ds-data-idrepo-0
  annotations:
    pv.beta.kubernetes.io/gid: "0"
spec:
  storageClassName: standard-rwo
  resources:
    requests:
      storage: 10Gi
  accessModes: [ "ReadWriteOnce" ]
  dataSource:
    name: ds-snapshot1
    kind: VolumeSnapshot
    apiGroup: snapshot.storage.k8s.io

```

Repeat the above PVC for ds-data-idrepo-1 and ds-data-idrepo-2.  If you use the ds-operator you
can initialize a cluster by specifying the snapshot in the Custom Resource Spec.

## Adhoc Restore Job

[ds-restore-volume](ds-restore-volume) performs an adhoc "one shot" restore.

You need to edit this example. The basic process is:

* Edit ds-restore-volume/restored-data-pvc.yaml and ds-restore-volume/take-snap.yaml.
* Run the restore. This creates a PVC with the restored data called "restored-ds-data" and a snapshot of the PVC called "restored-ds-data-snapshot". 

`kustomize build ds-restore-volume | kubectl apply -f -`

To rerun this job, first remove the existing job `kubectl delete job/ds-restore`.

NOTE: Subsequently the "restored-ds-data-snapshot" snapshot can be used in conjuction with the [ds-operator](https://github.com/forgerock/ds-operator) to be the initilization source of the data volume.

## Operational notes

* View the backup status from the cronjob or job logs.

