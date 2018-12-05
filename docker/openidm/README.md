# Dockerfile for ForgeRock IDM

Note - within the container, OpenIDM runs on port 8080.

# Secrets 

The docker-entrypoint.sh script looks for secrets mounted at /opt/openidm/secrets, and uses these
for the keystore, keystore pin, etc. Use a Kubernetes secret volume to mount these. The relevant files are:

* keystore.jceks - the OpenIDM keystore
* truststore  - trust store for cert chain verification 
* keystore.pin - file that contains the keystore / truststore password in clear text

You do not need to provide all of these files - the start script will use the defaults 
in conf/boot/boot.properties.