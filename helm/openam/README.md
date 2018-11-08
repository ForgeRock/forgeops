# Helm Chart for OpenAM 

# Quick Start

`helm install --set domain=.acme.com openam`

This chart depends on a having a ds configstore instance deployed and an instance of `frconfig` - that holds
the information needed to clone configutation from git.


# Implementation Notes

These are subject to change!

## Boot process

* An init container is used to copy in the files needed to boot AM into the home directory ~/openam. This includes the boot.json
  and the keystore files.
* AM needs a writable home directory (see https://bugster.forgerock.org/jira/browse/OPENAM-13841). It wants to
  rewrite the bootstrap file. For this reason, we can not mount the keystore.jceks and other files directly under ~/openam. This is why we use the init containers to copy in the template files. We will revisit this in 7.0.

 ## Keystores

Not all components in AM have been converted to use the new secrets API.  The session service (for example) assumes
 the default keystore.jceks is used. 
 
 There are in effect three different keystores in play:

* The keystore configured in boot.json. This keystore must be capable of being opened using a clear text storepass. This 
  needs to be located in ~/openam/. This keystore just needs the boot passwords for dsamesuser and the config store.
* The legacy keystore.jceks for the session and other legacy services. Can be the same keystore as above, but this is not a requirement.
* The new keystore supporting the new secrets API. This keystore is opened with the password secret provider configured in global settings. By default, the storepass is encrypted with the AM instance key. Therefore this keystore can only be opened once AM has booted. We change the default configuration to allow this keystore to be opened with a clear text storepass/entrypass.

The current approach is to copy in a prototype keystore from a k8s secret mounted at /var/run/secrets. The three keystore providers above
are all configured to point to this keystore.  The global password secret provider must be changed to use clear text passwords to open the 
keystore. This is found in the forgeops-init configuration that is imported by amster.



