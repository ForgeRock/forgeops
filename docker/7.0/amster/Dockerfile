FROM gcr.io/forgerock-io/amster:7.0.0-d0de590dcfb540d5a75161225b842622c73ce647

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]

