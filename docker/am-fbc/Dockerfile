FROM gcr.io/forgerock-io/am/pit1:7.0.0-201d336730940786fc129e1c51c5baab0727c191

# This is where you would copy in custom web.xml, add jar files, javascript, etc.
# The AM war is expanded to /usr/local/tomcat/webapps/am

# COPY web.xml /usr/local/tomcat/webapps/am/WEB-INF

# Finally - we copy in our file based config. If you use minikube hostPath overlays in "devMode"
# This gets overwritten.


COPY logback.xml /usr/local/tomcat/webapps/am/WEB-INF/classes
COPY --chown=forgerock:root docker-entrypoint.sh /usr/local/tomcat
COPY --chown=forgerock:root ./tmp /home/forgerock/

CMD ["/usr/local/tomcat/docker-entrypoint.sh"]