FROM gcr.io/forgerock-io/am/pit1:7.0.0-f0e19e1456c8aa08ef6b12907765ad3ace6c05bc

# BEGIN - temporary work around for testing if the ds-idrepo is configured before AM starts. Remove when FBC is integrated
# Installs ldap utils for querying the repo.
USER root
RUN apt-get update && apt-get install -y ldap-utils
USER forgerock
COPY --chown=forgerock:root openam /home/forgerock/openam
# END

COPY logback.xml /usr/local/tomcat/webapps/am/WEB-INF/classes


# This copies in the boot.json and other files...
COPY --chown=forgerock:root openam /home/forgerock/openam

# Override the entrypoint and just start tomcat
#CMD ["catalina.sh", "run"]

#ENTRYPOINT ["/bin/sh"]
# Use sh - because windows has issues with +x on the script
CMD ["bash", "-c", "/home/forgerock/openam/boot.sh"]
