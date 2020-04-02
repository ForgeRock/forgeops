FROM gcr.io/forgerock-io/ds-empty:7.0.0-b27d6fea6b99bdd08bfe6f4ae37c75654d227d71
USER root
RUN chown -R forgerock:root /opt/opendj

USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh
