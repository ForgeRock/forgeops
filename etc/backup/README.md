# Backup Strategies for the ForgeRock Identity Platform

For backup, use Kubernetes volume snapshots, and perform offline backups in another container:

* Kubernetes volume snapshots are now generally available in recent Kubernetes versions.
* With snapshots, you can rapidly restore a directory.
* Snapshots can be backed up by another pod that is not serving traffic, limiting the performance impact to the directory server.
* There are already a variety of "last mile" backup archival solutions such as S3, gcs, and minio. We provide samples to backup to a snapshot, and let you "bring your own" backup job to meet your specific requirements.
## Snapshot Backup Examples

The [../etc/ds](../etc/ds) directory contains an example of taking snapshots and backing them up to cloud storage. The sample demonstrates backup to a GCS bucket, but can be modified for other archival solutions.

The samples backup the contents of the directory using an LDIF export or
the dsbackup utility, which backs up the JE database. LDIF is recommended for long term archival of directory data.

## Other Backup Solutions

In addition to the strategies outlined above, other solutions in the Kubernetes ecosystem perform backup and restore. ForgeRock has tested [Velero](https://velero.io/).
### Velero Install Notes

Please refer to the [Velero Documentation](https://velero.io/docs) for installation and configuration instructions.

We've provided an example script [velero-install.sh](./velero-install.sh) that you can modify to install Velero in a GKE cluster.
After installation, you can test Velero to backup and restore your data. Here is a sample session:

```
kubectl create ns test
k ns test
bin/cdk install
# Deploy the cdk....

# Now backup the deployment in this namespace
velero backup create test-backup --include-namespaces test

# Get the details
velero backup describe test-backup --details

# Simulate a disaster
kubectl delete ns test

# restore the deployment
velero restore create --from-backup test-backup
```

# Notes

Velero currently has limitations restoring snapshot backups across geographical regions (US to EU, for example). Restore across regions in the same geography (example, us-west to us-east) works. See the links below:

* https://stackoverflow.com/questions/63460096/unable-to-restore-gcp-persistent-disks-pvcs-to-another-region-when-backing-up-gk/63504435#63504435
* https://github.com/vmware-tanzu/velero/issues/1624#issuecomment-671061689


