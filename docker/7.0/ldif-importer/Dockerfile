FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-857d5bf296343be7b41731ffbcd9acf7f3ab387d

USER 0
RUN apt-get update -y && apt-get install -y curl
USER 11111

COPY --chown=forgerock:root start.sh /opt/opendj
COPY --chown=forgerock:root ds-passwords.sh /opt/opendj
COPY --chown=forgerock:root external-am-datastore.ldif /opt/opendj

ENTRYPOINT /opt/opendj/start.sh

#CMD /opt/opendj/start.sh
