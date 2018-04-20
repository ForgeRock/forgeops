# AM Dockerfile
#
# Copyright (c) 2016-2017 ForgeRock AS.
#
FROM alpine:3.6

#  -Dcom.iplanet.services.debug.level=error

ENV FORGEROCK_HOME /home/forgerock
ENV OPENAM_HOME /home/forgerock/openam

# openldap-clients is needed to test for the configuration store.
RUN apk add --no-cache su-exec unzip curl bash openldap-clients \
    && mkdir -p $FORGEROCK_HOME \
    && addgroup -g 11111 forgerock \
    && adduser -s /bin/bash -h "$FORGEROCK_HOME" -u 11111 -D -G forgerock forgerock

USER forgerock


COPY *.sh $FORGEROCK_HOME/

ENTRYPOINT ["/home/forgerock/docker-entrypoint.sh"]


CMD ["pause"]