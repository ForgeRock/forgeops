FROM gcr.io/forgerock-io/amster/pit1:7.0.0-753f261785da7be85e5f61837542b0d6b5315347

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
