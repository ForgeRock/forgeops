
# Nightly build
FROM gcr.io/forgerock-io/am/docker-build:7.0.0-latest-postcommit


# For development, do not copy in the AM folder. There is a sequencing issue 
# where if this folder is present and the config store is *not* configured, AM will go into an error
# state.  Once the configstore is initialized, you can uncomment this line. If you
# are just doing development and are OK with AM being ephemeral - leave this commmented out.
# Note that if AM comes up faster than the configstore, it may error out. This gets
# fixed by K8S by restarting the pod - but it can take a couple of minutes.
#COPY --chown=forgerock:root openam /home/forgerock/openam

# Overide teh entrypoint and just start tomcat
CMD ["catalina.sh", "run"]

