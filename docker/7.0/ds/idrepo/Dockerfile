FROM gcr.io/forgerock-io/ds-empty:7.0.0-0e86d5739ced9e7438da0fa0856efeab04bf9235

USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh
