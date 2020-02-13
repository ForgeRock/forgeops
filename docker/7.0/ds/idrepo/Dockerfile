FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-0e86d5739ced9e7438da0fa0856efeab04bf9235
USER root
RUN chown -R forgerock:root /opt/opendj

USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh
