FROM gcr.io/forgerock-io/amster/pit1:7.0.0-403348d1081087c4bbcce7065884d52f71531702

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
