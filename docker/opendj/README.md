# ForgeRock OpenDJ Docker image

Listens on 1389/1636/4444/8989

Default bind credentials are CN=Directory Manager, the password defaults to "password".

To run with Docker (example)
```
mkdir dj    # Make an instance dir to persist data
docker run -it -v `pwd`/dj:/opt/opendj/data -p 1389:1389 forgerock/opendj:5.5.0
```

# Container Strategy 

This image separates out the read only bits (DJ binaries) from the volatile data.

All writable files and configuration (persisted data) is kept under /opt/opendj/data. The idea is that you will mount 
a volume (Docker Volume, or Kubernetes Volume) on /opt/opendj/data that will survive container restarts.

If you choose not to mount a persistent volume, OpenDJ will start fine - but you will lose your data when the container is removed.
 
# Environment Variable Summary

There are number of environment variables that control the behaviour of the container. These 
will typically be set by docker-compose or Kubernetes

* DIR_MANAGER_PW_FILE: Path to a file that contains the cn=Dir Manager password. 
* BOOTSTRAP:  Path to a shell script that will initialize OpenDJ. This is only executed if the data/config
directory is empty. Defaults to /opt/opendj/bootstrap/setup.sh
* SECRET_PATH:  Path to a directory containing keystores. Defaults to /var/run/secrets/opendj. This is used
to setup OpenDJ with known keystores. This would typically be a Kubernetes secret volume.
* BASE_DN: The base DN to create. Used in setup and replication. Defaults to `dc=openam,dc=forgerock,dc=org`
* DJ_MASTER_SERVER: If set, bootstrap/replicate.sh will enable replication to 
this master. This only happens at setup time. 

 
# Secrets
 
As is, the sample setup.sh script looks for a password in the path specified by DIR_MANAGER_PW_FILE. If this file does
not exist it will use "password". 

Note that the ads-truststore used for replication can not be mounted as a secret volume - as OpenDJ
needs to update this file at runtime. Make sure you do not have this keystore in your secret volume.


# Bootstrapping the configuration

When the image comes up, it looks for a backend database and configuration
under `/opt/opendj/data`. If a database exists, DJ boots up and starts to accept requests.

If no database is found, the script defined by BOOTSTRAP will be
executed.  The default script path can be overridden by setting the environment
variable BOOTSTRAP to the full path to the script.  To customize OpenDJ, 
mount a volume that contains your setup.sh script and set BOOTSTRAP to point to your startup.sh shell script. 
 
If you do not provide a bootstrap script, the default setup.sh creates a sample back end for a user data store
(BOOTSTRAP_TYPE=userstore).

If you set the environment variable BOOTSTRAP_TYPE=cts,  the bootstrap/cts setup scripts will be executed.

Examples provided under the bootstrap directory:

* bootstrap/cts/  - configures DJ for an AM CTS server 
* bootstrap/userstore/ - Configures DJ as a sample user data store.  If you want some sample 
users populated, set the environment variable `NUMBER_SAMPLE_USERS=100`.


# Backup  and Restore

See https://forgerock.org/opendj/doc/bootstrap/admin-guide/#chap-backup-restore 

The suggested strategy for Docker is to mount a volume on /opt/opendj/bak, and schedule DJ backups via the DJ cron 
facility. The backup files can then be moved to secondary storage. 

To take an immediate backup,  exec into the Docker image and run the `bin/backup.sh` command.

A copy of the /opt/opendj/data/config/ directory should also be saved as it contains the encryption keys for the 
server and the backup. If you lose the configuration you will not be able to recover the backup data. 

# Replication 

run.sh calls `replicate.sh` if DJ_MASTER_SERVER is set. The idea is that all servers
replicate to the master. This is a very simple strategy that works for small OpenDJ clusters.


# JVM tuning 

The env var OPENDJ_JAVA_ARGS can be set and will override the java.properties
in opendj/config. 


To use the G1 Garbage collector specify `-XX:+UseG1GC`

To Debug GC add: 
`-verbose:gc  -XX:+UseGCLogFileRotation -XX:NumberOfGCLogFiles=10 -XX:GCLogFileSize=100M`

The current default uses the experimental JVM CGroups feature to size DJ memory based on the containers
allocated memory.


# Readiness and Liveness probes.

Kubernetes recommends creating a probe to monitor the health of a container. The `probe.sh` script
can be used for this purpose. It returns 0 if the DJ server is responding, or non zero otherwise.


