# Backup and ldif export sample

This is a sample Job that will export DS data to LDIF or DS backup format. You will
need to modify this example for your usage.


Operation:

* The PVC containing the directory binary data can either be the StatefulSet PVC
 (for example, `data-ds-idrepo-0`), or a PVC created from a volume snapshot.
  A volume snapshot is provided as an example. If you want to use the STS
  PVC directly, the directory instance must be scaled to 0, as you can not
  mount a PVC on two pods at the same time.
* The Job runs as an init container and exports the DS data to a secondary mounted PVC volume `ds-backup`.
* At the conclusion of the job, the secondary PVC contains the data in LDIF or ds-backup format.
* The next job then runs an optional container where you can archive or otherwise save
 the exported files to a destination of your choice.
* A sample `pause` container is provided just sleeps, and you can use `kubectl cp` to pull the data from the pvc.
* A `gsutil` sample container copies the files to GCS cloud storage.

This diagram visualizes the process:

(ds-volume-backup.png)

## ds-backup or ldif format

To change the type of backup, edit `ds-backup-job.yaml` and set the BACKUP_TYPE to either ldif or ds-backup.

## Volume Snapshots

It is highly recommended to use snapshots for this job. It will make backup/restore much easier and safer.

Read your providers documentation on snapshots. Things to keep in mind:

* You need a volume snapshot class in your cluster. The sample here assumes `ds-snapshot-class` exists.
* Your PVCs need to be provisioned with a CSI storage driver. On GKE, the storage classes
  `standard-rwo` and `premium-rwo` are created when you enable the CSI driver on a GKE cluster.
* If taking a snapshot fails, you probably have the wrong driver or a missing storage class. `kubectl describe ` is useful for debugging.

## Sample Usage for export

Export:

* Deploy the directory service
* Take a snapshot of the data-ds-idrepo-0 disk:  `kubectl apply -f volume-snapshot.yaml`
* Run the export job:  `kustomize build . | kubectl apply -f -`
* Observe the logs from the pod or job (`stern export`)
* When the init container completes, the secondary PVC `ds-backup` will contain the exported files. The default is for all non-system backends to be exported.
* If you have gcs backup enabled (see gsutil.yaml and kustomization.yaml), the files will be copied to cloud storage. You will want to edit the scripts/gs* files for your environment.


## Cron

A sample is provided to run a cron task that backs up the data on a schedule. Edit kustommization.yaml to include this.

Note that the sample as-is will backup the *same* PVC data over and over again. Since this PVC is a onetime snapshot of the "real" ds-data-idrepo-0 disk,
you will not be backing up new data.  The process needs to modified to take a new snapshot (potentially also on a cron schedule) and use that
new snapshot to create the PVC to be backed up. The directory operator (ds-operator) may be enhanced in the future to include this functionality. The
cron example is provided as a starting point for this process.

