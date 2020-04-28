FROM gcr.io/forgerock-io/ds-empty:7.0.0-e0bb77f7aba5eea264ecca9791c524eaef99ebd3
USER root
RUN chown -R forgerock:root /opt/opendj

USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh
# Debug Kaniko - CLOUD-1955
#RUN find . -user root  && find . -name \*.wh
