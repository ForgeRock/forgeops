FROM gcr.io/forgerock-io/ds-empty:7.0.0-32cd17ccf87a8603a89716509db6156cd9f72d7b
USER root
RUN chown -R forgerock:root /opt/opendj

USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh
# Debug Kaniko - CLOUD-1955
#RUN find . -user root  && find . -name \*.wh