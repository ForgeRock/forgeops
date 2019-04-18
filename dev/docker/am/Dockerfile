
# Nightly build
FROM gcr.io/forgerock-io/am/docker-build:7.0.0-latest-postcommit

# BEGIN - temporary work around for testing if the idrepo is configured before AM starts. Remove when FBC is integrated
USER root
RUN apt-get update && apt-get install ldap-utils
USER 11111
COPY --chown=forgerock:root openam /home/forgerock/openam
CMD ["/home/forgerock/openam/boot.sh"]
# END 

# There is a sequencing issue 
# where if boot.json is present and the idrepo store is *not* configured, AM will go into an error
# state which it will not recover from.
# Once the idrepo is initialized, you can uncomment this line. Subsequent restarts 
# of AM will work as long as the idrepo PVC is not deleted. 
#
# If you are just doing development and are OK with AM being ephemeral - leave this commmented out.
# Note that if AM comes up faster than the idrepo, it may error out. This gets
# fixed by K8S by restarting the pod - but it can take a couple of minutes.

# This copies in the boot.json and other files...
# COPY --chown=forgerock:root openam /home/forgerock/openam

# Override the entrypoint and just start tomcat
#CMD ["catalina.sh", "run"]

