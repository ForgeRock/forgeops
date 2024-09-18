# Default DS image

This image supports a "dynamic" directory deployment where data _and_ configuration are stored on a persistent volume claim (PVC).
In this regard, it behaves more like a traditional VM install. Changes made at runtime are persisted to the PVC.

Note that directory setup is mostly performed at _runtime_, not docker build time. A default setup script is provided, but
 you can to bring your own script (BYOS) to customize the image.

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

> NOTE: Lifecycle scripts via a configmap are no longer supported. The DS docker image now contains the option to configure setup scripts for idrepo and cts separately.

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

## Development

See the inline comments in the Dockerfile and the docker-entrypoint.sh script.
