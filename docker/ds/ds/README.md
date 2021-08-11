# DS Dockerfile for the Directory Service Operator (ds-operator)

This image is used by the [ds-operator](https://github.com/ForgeRock/ds-operator). It supports a
a "mutable" directory deployment where data and configuration are stored on a persistent volume claim (PVC).
In this regard, it behaves more like a traditional VM install. Changes made at runtime are
persisted to the PVC.

Setup is performed at _runtime_, not docker build time. To accelerate the startup of
the cdk, there is a fastpath shortcut that untars a prototype ds-idrepo backend. In most cases
 you will want to bring your own script (BYOS) to customize the image.


## Default Scripts / Life-Cycle Hooks.

The image supports a number of "hooks" that can be used to run custom script actions at various stages of
the directory deployment. If the user does not provide
their own script, a default script is called (see the `default-scripts/` folder) .


The ds-operator  mounts user provided script on /opt/opendj/scripts. Set
the  `spec.scriptConfigMapName` field in the DirectoryService CR to the name of a configmap that holds your scripts. See the ds-operator project for examples.


The life cycle hooks are:

* `setup`: Called if the PVC data volume is empty. This should setup the directory server, including all
 backends, indexes and acis. The default script creates a "idrepo" and cts configuration suitable for running the ForgeOps CDK.
 * `backup`: Called by a ds-operator `DirectoryBackup` Job. The pod will have a `/backup` pvc mounted to hold backup files. The `/opt/opendj/data` will contain a clone (via snapshot) of the DS data. The backup script should perform any action needed to backup directory data from /opt/opendj/data to /backup. The provided sample  exports to LDIF format.
 * `restore`: Called by the `DirectoryRestore` Job. The Job will have a `/backup` pvc mounted that holds the data to be restored (ldif, dsbackup, etc.). The `/opt/opendj/data` directory will be mounted ready to be restored. The restore script should perform any action needed to restore directory data such ldif-import, or dsrestore. The provided default script imports from LDIF format. When the data restore is complete,
 the operator creates a volume snapshot of the data directory. This snapshot can be used to restore a cluster based on the snapshot.
 * `post-init`: If the user supplies a post-init script it will be called by the init container after the linking and index rebuilds are
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

