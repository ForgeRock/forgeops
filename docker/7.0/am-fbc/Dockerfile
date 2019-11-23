FROM gcr.io/forgerock-io/am/pit1:7.0.0-a652ec221f2f9d5cd76dbda06dd76b34d3f00822

# This is where you would copy in custom web.xml, add jar files, javascript, etc.
# The AM war is expanded to /usr/local/tomcat/webapps/am

# COPY web.xml /usr/local/tomcat/webapps/am/WEB-INF

# Finally - we copy in our file based config. If you use minikube hostPath overlays in "devMode"
# This gets overwritten.


COPY logback.xml /usr/local/tomcat/webapps/am/WEB-INF/classes
COPY --chown=forgerock:root docker-entrypoint.sh /usr/local/tomcat
COPY --chown=forgerock:root ./tmp /home/forgerock/

CMD ["/usr/local/tomcat/docker-entrypoint.sh"]