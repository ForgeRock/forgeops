# Backup Strategies for the ForgeRock Identity Platform when using the DS Operator

>CAUTION The DS Operator is deprecated and will be removed in a future release

For backup, use Kubernetes volume snapshots, and perform offline backups in another container:

* Kubernetes volume snapshots are now generally available in recent Kubernetes versions.
* With snapshots, you can rapidly restore a directory.
* Snapshots can be backed up by another pod that is not serving traffic, limiting the performance impact to the directory server.
* There are already a variety of "last mile" backup archival solutions such as S3, gcs, and minio. We provide samples to backup to a snapshot, and let you "bring your own" backup job to meet your specific requirements.
## Snapshot Backup Examples

The [*ds-backup-restore*](./ds-backup-restore) directory contains an example of taking snapshots and backing them up to Cloud Storage. The sample demonstrates backup to a GCS bucket, but can be modified for other archival solutions.

The [*ds-backup-restore-ds-operator*](./ds-backup-restore-ds-operator) directory contains an example of taking snapshots and backing them up to a separate backup PVC using DS Operator Custom Resources. Documentation can be found in the DS Operator [*README*](https://github.com/ForgeRock/ds-operator#backup-and-restore-preview).

The samples above back up the contents of the directory using an LDIF export or
the dsbackup utility, which backs up the JE database. LDIF is recommended for long term archival of directory data.