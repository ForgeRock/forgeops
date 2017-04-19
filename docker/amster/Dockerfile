# Amster Container that configures OpenAM.
#
#
# Copyright (c) 2016-2017 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file

FROM openjdk:8-jre-alpine

ADD *.zip /tmp/


# git is added to the container so we can optionally execute git commit, git push, etc.
RUN apk add --no-cache su-exec unzip curl git bash openssh-client \
    && mkdir -p /opt \
    && unzip -q /tmp/amster.zip -d /opt/amster \
    && rm /tmp/*.zip \
    && git config --global user.email "amster@autoexport.com" \
    && git config --global user.name "Amster auto-export user"


WORKDIR /opt/amster


ADD *.sh /opt/amster/

ENTRYPOINT ["/opt/amster/docker-entrypoint.sh"]

CMD ["configure"]