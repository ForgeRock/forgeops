FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-3065cd2b9486407cff78439ded9a7f814db02fc9

USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
RUN bin/setup.sh && rm bin/setup.sh



