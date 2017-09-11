# Amster Container that configures AM.
#
#
# Copyright (c) 2016-2017 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file

FROM forgerock/java:5.5.0

ADD *.zip /opt/forgerock

# git is added to the container so we can optionally execute git commit, git push, etc.
RUN unzip -q /opt/forgerock/amster.zip -d /opt/amster \
    && rm -f /opt/forgerock/amster.zip \
    && chmod 775 /opt/amster/amster

WORKDIR /opt/amster

ADD *.sh /opt/amster/

USER forgerock

# Add ssh keys needed for frconfig
RUN mkdir -p /opt/forgerock/.ssh  && \
    ssh-keyscan -p 7999 stash.forgerock.org >> ~/.ssh/known_hosts && \
    ssh-keyscan github.com >> ~/.ssh/known_hosts


ENTRYPOINT ["/opt/amster/docker-entrypoint.sh"]

CMD ["configure"]