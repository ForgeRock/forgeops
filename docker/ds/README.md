# Default PingDS image

This image supports a "dynamic" directory deployment where data _and_ configuration are stored on a persistent volume claim (PVC).
In this regard, it behaves more like a traditional VM install. Changes made at runtime are persisted to the PVC.

Note that directory setup is mostly performed at _runtime_, not docker build time. A default setup script is provided, but you can to bring your own script (BYOS) to customize the image.

## Pros / Cons

Pros:

* Schema and index changes can be made at runtime without restarting the pod or rolling the statefulset. This should provide greater runtime stability as the image
only needs to be upgraded for bug fixes or major feature updates.
* The docker image can be mounted read only by Kubernetes, providing additional
security. All writes are made to the  mounted persistent volume claim.
* The deployment behaves like a traditional VM install which provides greater
familiarity for administrators.
* Indexes and configuration can be unique to specific pod for special use cases. For
example, a directory pod could be dedicated to indexing an attribute that is required for batch processing.
* Backing up the PVC captures both data and configuration. A restore operation will restore the state exactly as-is.


Cons:

* Changes applied at runtime (for example, schema) must be captured, ideally
in "git" somewhere so that the environment can be recreated or promoted. A
disciplined approach to capturing these changes is needed as the schema
is not maintained as part of the Dockerfile. This could be as simple
as scripts maintained in git that update the schema. This is an adhoc
implementation of the concepts behind [Flyway](https://flywaydb.org/).

## Runtime Scripts.

> NOTE: Runtime scripts via a configmap are no longer supported. The PingDS docker image now contains the option to configure runtime scripts for idrepo and cts separately.

To configure runtime behaviour for ds-idrepo and ds-cts separately, use the runtime scripts provided for each server in the runtime-scripts directory.  The scripts are used as follows:

- setup: Intial setup runs on first deployment when the PVC contains no data.
- post-init: Additional setup runs on subsequent deployments when the PVC already contains data.  

## Certificates

The image is configured to use PEM based certificates instead of a Java Keystore (JKS). The provided Kubernetes sample
generates these certificates using [cert-manager](https://cert-manager.io). 

> WARNING: Directory data is encrypted using the private key
in the master-key certificate. You must back up certificates or
risk rendering all your data (including backups) unreadable.
The private key must be backed up. You can not recover data using
a newly generated certificate, even if that certificate is from
the same trusted CA.

As currently implemented, the pem keys are read from k8s secrets and copied to the PVC when the pod starts. If you backup the PVC using something like velero.io, the keys will be included in the file system backup. You must protect the backup carefully.

## Custom Schema updates
To provide a custom schema file, add your custom file to the config/schema directory 
prior to building your image.  There is a sample file in there for guidance.

## Custom LDAP entries
To provide an ldif file with custom ldap entries, add your custom file to:
- ldif-ext/am-config/ for the am-config backend
- ldif-ext/identities/ for the identities backend
- ldif-ext/tokens/ for the tokens backend
- ldif-ext/idm-repo/ for the openidm backend

To update any other backends, please update ds-setup.sh to copy the files to the relevant setup-profile.

## Backup/restore considerations

PingDS backups via the `dsbackup create` commands contain user data and its replication metadata.
The metadata must refer to the current contents of the changelog, to avoid divergences, meaning restoring the backup implies knowledge of when it was taken.
If it was taken within the replication purge delay interval, it can be used to restore a pod or the entire deployment; if it is older than the replication purge delay
it can only be used to restore the entire deployment.
Restoring the entire deployment is a *disaster recovery*, in Directory Server terminology and procedure. It involves additional steps beyond restoring a backup, the `dsrepl disaster-recovery` must be run post restore and before the server starts.
There are two documented procedures for disaster recovery, one requiring two different steps to make sure all controls about data coherency from the chosen source of data apply; one for deployments where data coherency is implied by automation and the two steps procedure cannot be easily automated.
The disaster recovery process resets some replication metadata to allow the new "version" of the topology, identified by a disaster recovery ID, to start accepting load. The reset is such that data pods not being recovered with the current disaster recovery ID do not exchange data with pods already recovered.

The restore/disaster recovery process is automated in Forgeops: when a restore happens, disaster recovery is also run with the disaster recovery ID defined in the configuration. If the disaster recovery ID matches the contents of the restored backup, it reverts to be a NO-OP, otherwise the data is disaster recovered.

The disaster recovery ID is configured in the platform-config configmap as follows:  
* For Helm: update ds_restore.disasterRecoveryId in your custom values file
* For Kustomize: update DISASTER_RECOVERY_ID in your custom overlay in base/platform-config.yaml

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

## Development

See the inline comments in the Dockerfile and the docker-entrypoint.sh script.
