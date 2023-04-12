# DS Dockerfile for the Directory Service Operator (ds-operator)

This image is used by the [ds-operator](https://github.com/ForgeRock/ds-operator). It supports a
a "dynamic" directory deployment where data _and_ configuration are stored on a persistent volume claim (PVC).
In this regard, it behaves more like a traditional VM install. Changes made at runtime are
persisted to the PVC.

Note that directory setup is mostly performed at _runtime_, not docker build time. A default setup script is provided, but
 you can to bring your own script (BYOS) to customize the image.

The image is also suitable for non operator deployment. The sample Kubernetes manifest provided at `../ds-k8s` can be used as a starting point.
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

## Default Scripts / Life-Cycle Hooks.

The image supports a number of "hooks" that can be used to run custom script actions at various stages of
the directory deployment. If the user does not provide
their own script, a default script is called (see the `default-scripts/` folder) .

The ds-operator  mounts user provided script on /opt/opendj/scripts. Set
the  `spec.scriptConfigMapName` field in the DirectoryService CR to the name of a configmap that holds your scripts. See the [ds-operator](https://github.com/ForgeRock/ds-operator) project.

While defaults are provided, the idea is to bring your owb scripts to implement the exact
desired behavior. This strategy provides flexibility to accommodate a wide range of use cases.

The life cycle hooks are:

* `setup`: Called if the PVC data volume is empty. This should setup the directory server, including all
 backends, indexes and acis. The default script creates a "idrepo" and cts configuration suitable for running the ForgeOps plaform deployment (CDK/CDM).
 * `backup`: Called by a ds-operator `DirectoryBackup` Job. This assumes the pod will have a `/backup` pvc mounted to hold backup files. The backup script should perform any action needed to backup directory data from the PVC to /backup. The provided sample  exports to LDIF format.
 * `restore`: Called by the `DirectoryRestore` Job. The Job will have a `/backup` pvc mounted that holds the data to be restored (ldif, dsbackup, etc.). The `/opt/opendj/data` PVC will be mounted ready to receive the restored data. The restore script should perform any action needed to restore directory data such `ldif-import`, or `dsrestore`. The provided default script imports from LDIF format. When the data restore is complete,
 the operator creates a volume snapshot of the data directory. This snapshot can be used to restore a cluster based on the snapshot.
 * `post-init`: If the user supplies a post-init script it will be called by the init container after index rebuilds are
 performed. Use this to add any new indexes before the server starts, or to issue other `dsconfig` commands. The directory is offline
 when this script is run.

An example of where `post-init` is useful is the addition of a new index. This can be done online, but needs to be
repeated on each pod where the index is required.  Instead, the index commands can be added to a post-init script:

```bash
#!/usr/bin/env bash
dsconfig --offline --no-prompt --batch <<EOF
create-backend-index \
          --backend-name amIdentityStore \
          --set index-type:equality \
          --index-name carLicense
EOF

rebuild-index  --offline \
 --baseDN ou=identities \
 --index carLicense
```

The configmap containing the script is updated using kustomize (see the ds-operator). When each ds pod restarts, this script will be executed, adding
the index to all ds pods.

## Certificates

The image is configured to use PEM based certificates instead of a Java Keystore (JKS). The provided Kubernetes sample
generates these certificates using [cert-manager](https://cert-manager.io). The ds-operator is
migrating to cert-manager, as it is the canonical method of generating certificates for
Kubernetes.

> WARNING: Directory data is encrypted using the private key
in the master-key certificate. You must back up certificates or
risk rendering all your data (including backups) unreadable.
The private key must be backed up. You can not recover data using
a newly generated certificate, even if that certificate is from
the same trusted CA.

As currently implemented, the pem keys are read from k8s secrets and copied to the PVC when the pod starts. If you backup the PVC using something like velero.io, the keys will be included in the file system backup. You must protect the backup carefully.

## Development

See the inline comments in the Dockerfile and the docker-entrypoint.sh script.
