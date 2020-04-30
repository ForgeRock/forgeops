FROM gcr.io/forgerock-io/ds-empty:7.0.0-5c94c12b1fffb15228ccf2fac2c670d5f504fe4c
USER root
RUN chown -R forgerock:root /opt/opendj

USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh
# Debug Kaniko - CLOUD-1955
#RUN find . -user root  && find . -name \*.wh
