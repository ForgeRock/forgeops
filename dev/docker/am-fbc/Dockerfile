
# This is an experimental FBC image created March 15
#FROM gcr.io/engineering-devops/am:7.0-FBC-test
# Nightly build

#FROM gcr.io/forgerock-io/am/docker-build:7.0.0-dd200ce14c
FROM gcr.io/forgerock-io/am/docker-build:7.0.0-latest-postcommit

# This is an image that results from a local build using mvn and minikube:
# cd openam-src/openam-docker; mvn docker:build 
#FROM docker-internal-snapshots.forgerock.io/forgerock/am:latest 


# This is where you would copy in custom web.xml, add jar files, javascript, etc.
# The AM war is expanded to /usr/local/tomcat/webapps/am

# COPY web.xml /usr/local/tomcat/webapps/am/WEB-INF

# Finally - we copy in our file based config. If you use minikube hostPath overlays in "devMode"
# This gets overwritten.

COPY --chown=forgerock:root ./tmp /home/forgerock/

CMD ["catalina.sh", "run"]
