FROM gcr.io/forgerock-io/am/pit1:7.0.0-9443891d8fa215c2e07f8ef7ac733ebbf0d1c8ca

# BEGIN - temporary work around for testing if the ds-idrepo is configured before AM starts. Remove when FBC is integrated
# Installs ldap utils for querying the repo.
USER root
RUN apt-get update && apt-get install -y ldap-utils
USER forgerock
COPY --chown=forgerock:root openam /home/forgerock/openam
# END

COPY logback.xml /usr/local/tomcat/webapps/am/WEB-INF/classes

ENV CATALINA_OPTS "-server -XX:MaxRAMPercentage=75 -Dcom.sun.identity.configuration.directory=/home/forgerock/openam -Dcom.iplanet.services.stats.state=off -Xlog:gc*,gc+ref=debug,gc+heap=debug,gc+age=trace:file=/tmp/gc-%p-%t.log:tags,uptime,time,level:filecount=10,filesize=10m"

# This copies in the boot.json and other files...
COPY --chown=forgerock:root openam /home/forgerock/openam

# Override the entrypoint and just start tomcat
#CMD ["catalina.sh", "run"]

#ENTRYPOINT ["/bin/sh"]
# Use sh - because windows has issues with +x on the script
CMD ["bash", "-c", "/home/forgerock/openam/boot.sh"]
