FROM gcr.io/forgerock-io/ds-empty:7.0.0-3d53887d6118fa1bd0d531e80ab233f3b35733f6
USER root
RUN chown -R forgerock:root /opt/opendj
USER forgerock
COPY --chown=forgerock:root idrepo /opt/opendj/
COPY --chown=forgerock:root scripts /opt/opendj/scripts
ARG profile_version
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh
