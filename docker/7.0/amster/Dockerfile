FROM gcr.io/forgerock-io/amster:7.0.0-f91da919a453e00cf83acf610410420f579969fc

USER root
RUN apt-get install -y openldap-utils jq
USER forgerock

ENV SERVER_URI /am

COPY --chown=forgerock:root . /opt/amster
