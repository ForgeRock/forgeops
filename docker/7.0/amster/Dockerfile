FROM gcr.io/forgerock-io/amster/pit1:7.1.0-155230a6d4b58d746c55ecc0981bcfce6b333ef3

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
