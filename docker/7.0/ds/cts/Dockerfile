FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-b93c14e88abbbb6ab8e7099872cae509663b00bd

USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
# Kaniko: https://github.com/GoogleContainerTools/kaniko/issues/9
#RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh
RUN bin/setup.sh "$profile_version"
