FROM forgerock/openam:5.5.1

COPY WEB-INF /usr/local/tomcat/webapps/openam/WEB-INF
COPY XUI /usr/local/tomcat/webapps/openam/XUI
COPY secrets /var/run/secrets/openam

USER root

RUN chmod 400 /var/run/secrets/openam/.*pass && \
    chmod 640 /var/run/secrets/openam/* && \
    chown forgerock:forgerock /var/run/secrets/openam/.*pass && \
    chown forgerock:forgerock /var/run/secrets/openam/*

USER forgerock
