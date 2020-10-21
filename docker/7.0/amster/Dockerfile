FROM gcr.io/forgerock-io/amster:7.1.0-PAAS-GA-f101d8bdaceec7a19ce72f2683b60d4cc76f181f

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster

ENTRYPOINT [ "/opt/amster/docker-entrypoint.sh" ]
