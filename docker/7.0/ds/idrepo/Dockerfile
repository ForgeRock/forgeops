FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-8243f35996f0bd5baf4d152d8e9a6f2a54b0a2e6
USER root
RUN chown -R forgerock:root /opt/opendj

USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh
# Debug Kaniko - CLOUD-1955
#RUN find . -user root  && find . -name \*.wh