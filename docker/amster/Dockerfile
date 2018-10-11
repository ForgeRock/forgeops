# Amster Container that configures AM.
#
#
# Copyright (c) 2016-2017 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file
FROM forgerock/downloader:latest

ARG VERSION="6.5.0-M9"
RUN download -v $VERSION amster
RUN mkdir -p /var/tmp/amster && unzip -q /amster.zip -d /var/tmp/amster

FROM forgerock/java:6.0.0

COPY --from=0 /var/tmp/amster /opt/amster

#COPY *.zip /opt/forgerock

COPY *.sh /opt/amster/
# put these in the path as well - for convenience.
COPY *.sh /usr/local/bin/

# git is added to the container so we can optionally execute git commit, git push, etc.
RUN chmod 775 /opt/amster/amster \
    && chown -R forgerock /opt

WORKDIR /opt/amster

USER 11111

ENTRYPOINT ["/opt/amster/docker-entrypoint.sh"]

CMD ["configure"]
