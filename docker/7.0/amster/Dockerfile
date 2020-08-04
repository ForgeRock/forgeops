FROM gcr.io/forgerock-io/amster:7.0.0-726a7b3ff28ae4425660c314fcfd306b0d57f1ee

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]

