FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-9a4f92b35610ad3925abe947dd237466bfafd4bb

USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh
