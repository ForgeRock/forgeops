#
# Copyright (c) 2016-2017 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file
#
# Docker image for Apache + AM HTTP agent.
FROM httpd:2.4
WORKDIR /opt
# Shared memory cache size in bytes. The default is 1.5 GB. On Docker you need to run with --shm-size.
# Set this lower for testing purposes only. The settings below allow you to run with --shm-size=200m
# See https://bugster.forgerock.org/jira/browse/AMAGENTS-383.
# Remove this when https://bugster.forgerock.org/jira/browse/AMAGENTS-273 is resolved.
#ENV AM_MAX_SHARED_POOL_SIZE 0x200000
#ENV AM_MAX_SESSION_CACHE_SIZE 0x4000000

ENV AM_MAX_SHARED_POOL_SIZE 1048576000
ENV AM_DEFAULT_LOG_LEVEL All

# For testing purposes, you can build this image with ARGs to match your
# deployment
ARG AM_SERVER=http://openam.example.forgeops.com:80/openam
ARG AGENT_SERVER=http://apache-agent.example.forgeops.com

# Given agent builds are residing in internal network, we need to download
# them before running docker build and save them to Dockerfile folder as agent.zip
ARG APACHE_AGENT=/var/tmp/agent.zip
COPY agent.zip /var/tmp/agent.zip

# Install needed sw
RUN apt-get update && apt-get install --no-install-recommends  -y unzip curl vim && \
      unzip -q /var/tmp/agent.zip && rm /var/tmp/agent.zip && \
      echo "password" >/var/tmp/pw.txt  && chmod 0400 /var/tmp/pw.txt && \
      rm -rf /var/lib/apt/lists/*

# Do a force installation. We are going to overwrite agent.conf file later on
RUN /opt/web_agents/apache24_agent/bin/agentadmin --s /usr/local/apache2/conf/httpd.conf \
        "$AM_SERVER"  \
        "$AGENT_SERVER" \
        "/" \
        "apache" \
        /var/tmp/pw.txt \
        --changeOwner --acceptLicence --forceInstall

WORKDIR /opt/web_agents/apache24_agent
COPY *.sh /opt/web_agents/
COPY agent.conf /opt/web_agents/apache24_agent/instances/agent_1/config/

# Copy testing pages to htdocs
COPY neu.html /usr/local/apache2/htdocs/
COPY policy.html /usr/local/apache2/htdocs/

RUN echo "CoreDumpDirectory /tmp/" >> /usr/local/apache2/conf/httpd.conf
ENTRYPOINT ["/opt/web_agents/docker-entrypoint.sh"]

# Inherit CMD from Parent httpd:2.4. This starts Apache in the foreground, so we can see the stdout.
CMD ["/opt/web_agents/docker-entrypoint.sh"]
