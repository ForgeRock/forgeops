FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-9273ecc9f7ab4896a7bb7a9264c898eb2966de72
USER root
RUN chown -R forgerock:root /opt/opendj
USER forgerock
COPY --chown=forgerock:root idrepo /opt/opendj/
COPY --chown=forgerock:root scripts /opt/opendj/scripts
ARG profile_version
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh
