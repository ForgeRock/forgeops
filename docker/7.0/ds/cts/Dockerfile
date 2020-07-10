FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-0df350e7b7ee3f5ef157a9c07223358c4e7ab58f
USER root
RUN chown -R forgerock:root /opt/opendj
USER forgerock
COPY --chown=forgerock:root cts /opt/opendj/
COPY --chown=forgerock:root scripts /opt/opendj/scripts
ARG profile_version
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh