FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-d1b550a4b28ab33065c495d1260dc9e38732161e
USER root
RUN chown -R forgerock:root /opt/opendj

USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh
# Debug Kaniko - CLOUD-1955
#RUN find . -user root  && find . -name \*.wh