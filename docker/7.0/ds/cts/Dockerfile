FROM gcr.io/forgerock-io/ds-empty/pit1:7.0.0-1f10520120fc09fed48955487c00ee0bf05efb31
USER root
RUN chown -R forgerock:root /opt/opendj
USER forgerock
COPY --chown=forgerock:root .  /opt/opendj/
ARG profile_version
USER forgerock
RUN bin/setup.sh "$profile_version"  && rm bin/setup.sh
# CLOUD-1955
#RUN find . -user root  && find . -name \*.wh