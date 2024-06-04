# Directory Server (DS) Customization and Utilities

**NOTE**

The current production image is in the `ds-new` folder.

The pre 7.3.0 images cts and idrepo here are for reference and ForgeOps internal use only.

## Directory folders

* ds-new - The default DS image used in all ds deployments
* common: common scripts used to build multiple images
* cts:  Legacy DS image purpose-built for CTS. ** For internal purposes only **
* idrepo: Legacy DS image purpose-built for DS as the shared repository for AM/IDM. Also includes a CTS backend for small installations. ** For internal purposes only **
* proxy: DS proxy server. Experimental / unsupported.
* dsutil:  Utility image that can be run in a pod to perform various DS related tasks. Has all the DS tools installed.

## Utility image (`dsutil`)

The `dsutil` image provides a bash shell into a pod that has all the DS utility scripts installed in the /opt/opendj/bin directory.

To build the `dsutil` image:

```
gcloud builds submit .
```

To run the `dsutil` image:

```
kubectl run -it dsutil --image=us-docker.pkg.dev/forgeops-public/images/ds-util --restart=Never -- bash
```

To create a shell alias for the above command:

```
alias fdebug='kubectl run -it dsutil --image=us-docker.pkg.dev/forgeops-public/images/ds-util --restart=Never -- bash'
```

## Backup/restore considerations

DS backups via the `dsbackup create` commands contain user data and its replication metadata.
The metadata must refer to the current contents of the changelog, to avoid divergences, meaning restoring the backup implies knowledge of when it was taken.
If it was taken within the replication purge delay interval, it can be used to restore a pod or the entire deployment; if it is older than the replication purge delay
it can only be used to restore the entire deployment.
Restoring the entire deployment is a *disaster recovery*, in Directory Server terminology and procedure. It involves additional steps beyond restoring a backup, the `dsrepl disaster-recovery` must be run post restore and before the server starts.
There are two documented procedures for disaster recovery, one requiring two different steps to make sure all controls about data coherency from the chosen source of data apply; one for deployments where data coherency is implied by automation and the two steps procedure cannot be easily automated.
The disaster recovery process resets some replication metadata to allow the new "version" of the topology, identified by a disaster recovery ID, to start accepting load. The reset is such that data pods not being recovered with the current disaster recovery ID do not exchange data with pods already recovered.

The restore/disaster recovery process is automated in Forgeops: when a restore happens, disaster recovery is also run with the disaster recovery ID defined in the configuration. If the disaster recovery ID matches the contents of the restored backup, it reverts to be a NO-OP, otherwise the data is disaster recovered.

The use cases covered by ForgeOps are:

### New topology from backup
Define the backup to be restored
If desired, define the disaster recovery ID to use instead of the provided default value

### DR of existing topology
Define the backup to be restored
Change the disaster recovery ID to a new value

### Restore of a single instance, rest of topology still valid
Define the backup to be restored. The backup *must* be recent, according to the replication purge delay as described
Do not change the disaster recovery ID, it should be the same as the last topology recovery

### New pod (scale up):
Same as restore of single instance
