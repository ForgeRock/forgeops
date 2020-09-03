FROM gcr.io/forgerock-io/amster/pit1:7.1.0-ee645ad0488b11f2fb9cc75a2b916e9bc78d3471

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
