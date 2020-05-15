FROM gcr.io/forgerock-io/ds-empty:7.0.0-a109646e9139fb5011766a848a5f4c020b8281fc
USER root
RUN chown -R forgerock:root /opt/opendj
USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
USER forgerock
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh
# CLOUD-1955
#RUN find . -user root  && find . -name \*.wh