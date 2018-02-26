# Amster Container that configures AM.
#
#
# Copyright (c) 2016-2017 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file

FROM forgerock/java:6.0.0

COPY *.zip /opt/forgerock

COPY *.sh /opt/amster/

# git is added to the container so we can optionally execute git commit, git push, etc.
RUN unzip -q /opt/forgerock/amster.zip -d /opt/amster \
    && rm -f /opt/forgerock/amster.zip \
    && chmod 775 /opt/amster/amster \
    && chown -R forgerock /opt

WORKDIR /opt/amster

USER 11111

ENTRYPOINT ["/opt/amster/docker-entrypoint.sh"]

CMD ["configure"]