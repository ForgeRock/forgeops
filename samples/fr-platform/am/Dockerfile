FROM forgerock-docker-public.bintray.io/forgerock/openam:6.0.0

COPY WEB-INF /usr/local/tomcat/webapps/openam/WEB-INF
COPY XUI /usr/local/tomcat/webapps/openam/XUI
COPY secrets /home/forgerock/openam/openam

USER root

RUN chmod 400 /home/forgerock/openam/openam/.*pass && \
    chmod 640 /home/forgerock/openam/openam/* && \
    chown -R forgerock:forgerock /home/forgerock/openam


USER forgerock
