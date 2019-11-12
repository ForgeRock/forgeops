FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-2c427830c5d113f844a31667fd1afa2c5296a950

USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
RUN bin/setup.sh && rm bin/setup.sh
