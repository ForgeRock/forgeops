# dsadmin - Directory Service Administration Chart

At present this chart is optional and has limited functionality. In the future it may be extended with
additional capabilites to manage a number of directory server instances.

The current functions of this chart:

* Creates a dsadmin deployment. This runs a pod with the directory server tools installed. The pod sleeps, waiting for you to exec into the it to run various commands (ldap-modify, etc.).
* Optionally creates a Persistent Volume (PV) and Persistent Volume claim (PVC) for an nfs server where backups will be stored. The ds/ helm chart can mount this volume for backup and restore.


You need only a single instance of this chart, even if you many directory server deployements.