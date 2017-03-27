# ForgeRock OpenDJ Docker image

Listens on 389/636/4444/8989

Default bind credentials are CN=Directory Manager, the password defaults to "password"
if you run this as-is, or 'changeme' if you use the docker-compose example. 


Docker compose is the easiest way to experiment with this image. To run with docker-compose

```
docker-compose build
docker-compose up 
```

To run with Docker (example)
```
mkdir dj    # Make an instance dir to persist data
docker run -i -t -v `pwd`/dj:/opt/opendj/data forgerock/opendj
```

# Container Strategy 

This image separates out the read only bits (DJ binaries) from the volatile data.

All writable files and configuration (persisted data) is kept under /opt/opendj/data. The idea is that you will mount 
a volume (Docker Volume, or Kubernetes Volume) on /opt/opendj/data that will survive container restarts.

If you choose not to mount a persistent volume OpenDJ will start fine - but you will lose your data when the container 
 is removed.
 
# Environment Variable Summary

There are number of environment variables that control the behaviour of the container. These 
will typically be set by docker-compose or Kubernetes

* DIR_MANAGER_PW_FILE: Path to a file that contains the Dir Manager password. This is needed when the image is
first created
* BOOTSTRAP:  Path to a shell script that will initialize OpenDJ. This is only executed if the data/config
directory is empty. Defaults to /opt/opendj/boostrap/setup.sh
* SECRET_VOLUME:  Path to a directory containing keystores. Defaults to /var/secrets/opendj. This is used
to setup OpenDJ with known keystore values.
* BASE_DN: The base DN to create. Used in setup and replication
* DJ_MASTER_SERVER: If set, run.sh will call bootstrap/replicate.sh to enable replication to 
this master. This only happens if the data/config directory does not exist

 
# Secrets
 
For "secrets" such as the Directory Manager password, and for key and trust stores, you 
can mount a secret volume on the path defined by SECRET_VOLUME. If you do not do this a default password
will be used, and new key and trust stores will be generated. 

As is, the sample setup.sh script looks for a password in the path specified by DIR_MANAGER_PW_FILE. If this file does
not exist it will use "password". 

The provided docker-compose file demonstrates how to mount a secret volume for passwords and key stores. It
sets the Directory Manager password to "cangetin". 

Note that the ads-truststore used for replication can not be mounted as a secret volume - as OpenDJ
needs to update this file at runtime. Make sure you do not have this keystore in your secret volume.


# Bootstrapping the configuration

When the image comes up, it looks for a backend database and configuration
under /opt/opendj/data

If no database exists, the script defined by BOOTSTRAP will be
run.  The default script path can be overridden by setting the environment
variable BOOTSTRAP to the full path to the script.  To customize OpenDJ, 
mount a volume on /opt/opendj/bootstrap/ that contains your setup.sh
script. 
 
If you do not provide a bootstrap script, the default setup.sh creates a sample back end.

A couple of examples are provided under the bootstrap directory:

* bootstrap/cts/  - configures DJ for an OpenAM CTS server 
* bootstrap/replicate.sh - sets up a master and a replica server. See the dj-replica.yml
Docker compose file for an example of how run two masters.


# Backup  and Restore


See https://forgerock.org/opendj/doc/bootstrap/admin-guide/#chap-backup-restore 

The suggested strategy for Docker is to mount a volume on /opt/opendj/bak, and schedule DJ backups via the DJ cron 
facility. The backup files can then be moved to secondary storage. 

To take an immediate backup,  exec into the Docker image and run the bin/backup command manually.

A copy of the /opt/opendj/data/config/ directory should also be saved as it contains the encryption keys for the server and the backup. If you lose the configuration you will not be able to recover the backup data. 

# Replication 

run.sh calls bootstrap/replicate.sh if DJ_MASTER_SERVER is set. The idea is that all servers
replicate to the master. This is a very simple strategy that works for small OpenDJ clusters.


# JVM tuning 

The env var OPENDJ_JAVA_ARGS can be set and will override the java.properties
in opendj/config. 


To use the G1 Garbage collector specify -XX:+UseG1GC 


To Debug GC add: 
-verbose:gc  -XX:+UseGCLogFileRotation -XX:NumberOfGCLogFiles=10 -XX:GCLogFileSize=100M



