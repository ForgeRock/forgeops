FROM gcr.io/forgerock-io/amster/pit1:7.0.0-1266780722227873e257869f8561fde24c34c64f

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
