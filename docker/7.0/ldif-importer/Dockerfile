FROM gcr.io/forgerock-io/ds/pit1:7.0.0-ldif-importer

USER 0
RUN apt-get update -y && apt-get install -y curl
USER 11111

COPY --chown=forgerock:root start.sh /opt/opendj
COPY --chown=forgerock:root ds-passwords.sh /opt/opendj
COPY --chown=forgerock:root external-am-datastore.ldif /opt/opendj

ENTRYPOINT /opt/opendj/start.sh

#CMD /opt/opendj/start.sh
