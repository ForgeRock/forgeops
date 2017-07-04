# Amster Container that configures OpenAM.
#
#
# Copyright (c) 2016-2017 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file

FROM forgerock/java:5.5.0

ADD *.zip /opt/forgerock


# git is added to the container so we can optionally execute git commit, git push, etc.
RUN unzip -q /opt/forgerock/amster.zip -d /opt/amster \
    && rm -f /opt/forgeorock/*.zip

WORKDIR /opt/amster

ADD *.sh /opt/amster/

USER forgerock

ENTRYPOINT ["/opt/amster/docker-entrypoint.sh"]

CMD ["configure"]