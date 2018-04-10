# ForgeRock OpenDJ Docker image

Listens on 1389/1636/4444/8989

Default bind credentials are CN=Directory Manager, the password defaults to "password".

To run with Docker (example)
```
docker run -it -p 1389:1389 forgerock/opendj
```

This image is designed to be orchestrated using Kubernetes. See the helm chart in ../../helm/opendj.


There are number of environment variables that control the behaviour of the container. These
will typically be set by docker-compose or Kubernetes

* DIR_MANAGER_PW_FILE: Path to a file that contains the cn=Dir Manager password.
* BOOTSTRAP:  Path to a shell script that will initialize OpenDJ. This is only executed if the data/config
directory is empty. Defaults to /opt/opendj/bootstrap/setup.sh
* SECRET_PATH:  Path to a directory containing keystores. Defaults to /var/run/secrets/opendj. This is used
to setup OpenDJ with known keystores. This would typically be a Kubernetes secret volume.
* BASE_DN: The base DN to create. Used in setup and replication.

# Secrets

As is, the sample setup.sh script looks for a password in the path specified by DIR_MANAGER_PW_FILE. If this file does
not exist it will use "password".

Note that the ads-truststore used for replication can not be mounted as a secret volume - as OpenDJ
needs to update this file at runtime. Make sure you do not have this keystore in your secret volume.

# Entry points

There are a number of different entry points in docker-entrypoint.sh that are used for operating modes:

* start - starts up a DS instance. Assumes that the ds has already been setup.
* setup - Runs the setup process to create a new ds instance.
* run - Runs setup followed by start.
* run-post-setup-job - Runs a job that configures replication and backup after all DS nodes have been created.
* restore-from-backup - restores from a backup. This will not overwrite existing data.
* restore-and-verify - restores from a backup, and verifies the integrity of the data. This is used as part of a 
cron job to test the integrity of backed up data.

# Bootstrapping the configuration


The script defined by BOOTSTRAP will be
executed to setup ds.   The default script path (bootstrap/setup.sh) can be overridden by setting the environment
variable BOOTSTRAP to the full path to the script.  To customize OpenDJ,
mount a volume that contains your setup.sh script and set BOOTSTRAP to point to your startup.sh shell script.

If you do not provide a bootstrap script, the default setup.sh creates an instance with backends for
`o=userstore` and `o=cts` 

If you want sample
users populated, set the environment variable `NUMBER_SAMPLE_USERS=100`.


# Backup  and Restore

See https://ea.forgerock.com/docs/ds/admin-guide/#chap-backup-restore 

The suggested strategy for Docker is to mount a volume on /opt/opendj/bak, and schedule DJ backups via the DJ cron
facility. The backup files can then be moved to secondary storage.

To take an immediate backup, exec into the container and run the `scripts/backup.sh` command.

A copy of the /opt/opendj/data/config/ directory should also be saved as it contains the encryption keys for the
server and the backup. If you lose the configuration you will not be able to recover the backup data.



# JVM tuning

The env var OPENDJ_JAVA_ARGS can be set and will override the java.properties
in opendj/config.


To use the G1 Garbage collector specify `-XX:+UseG1GC`

To Debug GC add:
`-verbose:gc  -XX:+UseGCLogFileRotation -XX:NumberOfGCLogFiles=10 -XX:GCLogFileSize=100M`

The current default uses the experimental JVM CGroups feature to size DJ memory based on the containers
allocated memory.
