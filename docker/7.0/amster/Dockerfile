FROM gcr.io/forgerock-io/amster/pit1:7.1.0-497657d173a7890ef6d2c0c5b0895cfb0aaaffd8

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
