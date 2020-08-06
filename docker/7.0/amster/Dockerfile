FROM gcr.io/forgerock-io/amster/pit1:7.0.0-d49dfa4fccb3e393456826beaa2731666a81d6aa

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
