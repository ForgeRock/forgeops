FROM gcr.io/forgerock-io/ds-empty:7.0.0-bc692008636cf9520635e83b767bf158b5360671

USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
RUN bin/setup.sh "$profile_version" && rm bin/setup.sh



