#
# Copyright (c) 2016-2017 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file
#
# Docker image for Apache + AM HTTP agent.
FROM httpd:2.4

WORKDIR /opt



# Use this if you want to directly add the agent zip file.
#ADD agent.zip /var/tmp/agent.zip

# The agent bits are not on maven - so we need to download these from the internal build server.
# If you are outside of ForgeRock you will need to adjust for your environment, or just copy the agent.zip into this folder.
ARG WEB_AGENT_BUILDS=http://abondance-uk.internal.forgerock.com/public/webagents/engineering_master/Linux/
ARG APACHE_AGENT=Apache_v24_Linux_64bit_5.0.0-SNAPSHOT.zip

RUN apt-get update && apt-get install --no-install-recommends  -y unzip curl vim && \
      curl $WEB_AGENT_BUILDS/$APACHE_AGENT -o /var/tmp/agent.zip && \
      unzip -q /var/tmp/agent.zip && rm /var/tmp/agent.zip && \
      echo "password" >/var/tmp/pw.txt  && chmod 0400 /var/tmp/pw.txt && \
      rm -rf /var/lib/apt/lists/*

# Format of agentadmin command:
# agentadmin --s "web-server configuration file, directory or site parameter" \
#                "AM URL" "Agent URL" "realm" "agent user id" \
#                "path to the agent password file" [--changeOwner] [--acceptLicence] [--forceInstall]
#


# Shared memory cache size in bytes. The default is 1.5 GB. On Docker you need to run with --shm-size.
# Set this lower for testing purposes only. The settings below allow you to run with --shm-size=200m
# See https://bugster.forgerock.org/jira/browse/AMAGENTS-383.
# Remove this when https://bugster.forgerock.org/jira/browse/AMAGENTS-273 is resolved.
#ENV AM_MAX_SHARED_POOL_SIZE 0x200000
#ENV AM_MAX_SESSION_CACHE_SIZE 0x4000000

ENV AM_MAX_SHARED_POOL_SIZE 1048576000

ENV AM_DEFAULT_LOG_LEVEL All



ARG AMSERVER=http://openam.default.192.168.99.100.xip.io:80/openam

#ARG AMSERVER="http://openam:80/openam"

# Because we are running this before AM is up and running we need to use the forceinstall option.
# We are using  defaults here (AM service name) that are not going to exist in most environments.
# They will need to be overridden at runtime by updating the bootstrap files.
# Note: Another alternative to bootstrapping the agent in the docker build is to move this into the container startup. 
RUN /opt/web_agents/apache24_agent/bin/agentadmin --s /usr/local/apache2/conf/httpd.conf \
         "http://openam.default.192.168.99.100.xip.io:80/openam"  \
         "http://apache-agent:80/" \
        "/" \
        "apache" \
        /var/tmp/pw.txt \
        --changeOwner --acceptLicence --forceInstall



WORKDIR /opt/web_agents/apache24_agent

# overwrites agent.conf
ADD agent.conf /opt/web_agents/apache24_agent/instances/agent_1/config

ADD *.sh /opt/web_agents/

# This sends the debug logs to stderr so we can use docker tools to view the logs.
RUN ln -sf /dev/stderr /opt/web_agents/apache24_agent/instances/agent_1/logs/debug/debug.log


RUN echo "CoreDumpDirectory /tmp/" >> /usr/local/apache2/conf/httpd.conf


ENTRYPOINT ["/opt/web_agents/docker-entrypoint.sh"]

# Inherit CMD from Parent httpd:2.4. This starts Apache in the foreground, so we can see the stdout.
CMD ["httpd-foreground"]