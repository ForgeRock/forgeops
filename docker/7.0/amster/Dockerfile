FROM gcr.io/forgerock-io/amster/pit1:7.1.0-6eeb85d4dc05277996a4ce65f811f9e1179d2301

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
