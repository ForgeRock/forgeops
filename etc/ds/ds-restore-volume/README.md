# Restore LDIF or a DS backup

This is a sample Job that will restore DS data in LDIF or DS backup format.

NOTES:

* You will need to modify this example for your usage.
* This shares kustomization files from [../ds-backup-volume/base](../ds-backup-volume/base).
* Please read [../ds-backup-volume](../ds-backup-volume) to understand how the backup files are created.

Operation:

* The job expects the files to be restored to be on an `ds-backup` PVC.
* You must either create a customer container or process
 to copy these files to this pvc, or reuse the ds-backup pvc created by the ../ds-backup-volume process.
* A sample `gsutil` container is provided that copies files from cloud storage. This fulfills the contract above: At
 termination the gsutil init container, the files to be restored to DS will be on the PVC.
* The StatefulSet data pvc (e.g. ds-idrepo-0) can not be in use if you are trying to restore data directly to it. You can scale DS to zero and directly mount the pvc
  (for example, data-ds-idrepo-0).
* Alternatively, restore data to a new PVC, and then create a volume snapshot of that PVC. The volume snapshot is
 then used to initialize all the DS instances in the set from scratch. This is done by setting the pvc volume source to the snapshot:

```
# Add to pvc spec:
dataSource:
    name: my-restored-snapshot1
    kind: VolumeSnapshot
    apiGroup: snapshot.storage.k8s.io

```

Where `my-restored-snapshot1` is the snapshot that holds the recovered directory instance.


## LDIF vs ds-backup

The job can restore LDIF files (via ldif-import) or ds-backup format.

ds-backup format files are encrypted. The ds keystore must be available to the job to restore a ds backup.

To change the restore format, edit [ds-restore-job.yaml](ds-restore.yaml) and set the BACKUP_TYPE to either ldif or ds-backup


