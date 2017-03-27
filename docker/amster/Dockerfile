# Container that configures OpenAM.
# Includes configurator, and will eventually contain Amster / REST based config.
#
# Copyright (c) 2016-2017 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file

FROM openjdk:8-jre-alpine

ADD *.zip /tmp/


RUN apk add --no-cache su-exec unzip curl git \
    && unzip -q /tmp/amster.zip -d /var/tmp/amster \
    && rm /tmp/*.zip


WORKDIR /var/tmp


ADD *.sh /var/tmp/

ENTRYPOINT ["/var/tmp/docker-entrypoint.sh"]

CMD ["configure"]