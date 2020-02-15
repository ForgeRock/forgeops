FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-fa39a8c221a8a86ab15124cc17b7f2918b5cde7d

USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh
