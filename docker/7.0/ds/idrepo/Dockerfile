FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-9a3f6c2f35ac5899b0af2009e8656cdb179745e8
USER root
RUN chown -R forgerock:root /opt/opendj
USER forgerock
COPY --chown=forgerock:root idrepo /opt/opendj/
COPY --chown=forgerock:root scripts /opt/opendj/scripts
ARG profile_version
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh
