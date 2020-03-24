FROM gcr.io/forgerock-io/amster/pit1:7.0.0-eb189f449da329e83af37e326838c79a65e20ca9

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
