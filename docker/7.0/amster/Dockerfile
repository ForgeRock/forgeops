FROM gcr.io/forgerock-io/amster:7.0.0-09d8c60c905dfc6b3fa46acef2785ccf91311865

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
