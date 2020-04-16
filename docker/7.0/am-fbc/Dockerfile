FROM gcr.io/forgerock-io/am:7.0.0-697984eee231a709328320058d0fcefd00c68d26

# This is where you would copy in custom web.xml, add jar files, javascript, etc.
# The AM war is expanded to /usr/local/tomcat/webapps/am

# COPY web.xml /usr/local/tomcat/webapps/am/WEB-INF

# Finally - we copy in our file based config. If you use minikube hostPath overlays in "devMode"
# This gets overwritten.


COPY logback.xml /usr/local/tomcat/webapps/am/WEB-INF/classes
COPY --chown=forgerock:root docker-entrypoint.sh /usr/local/tomcat
COPY --chown=forgerock:root ./tmp /home/forgerock/

CMD ["/usr/local/tomcat/docker-entrypoint.sh"]