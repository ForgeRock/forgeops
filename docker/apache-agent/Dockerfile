#
# Copyright (c) 2016-2017 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file
#
# Docker image for Apache + OpenAM HTTP agent.
FROM httpd:2.4

WORKDIR /opt

#ADD agent.zip /var/tmp/agent.zip

RUN apt-get update && apt-get install --no-install-recommends  -y unzip curl && \
     curl "http://download.forgerock.org/downloads/openam/webagents/nightly/Linux/Apache_v24_Linux_64bit_5.0.0-SNAPSHOT.zip" \
               -o /var/tmp/agent.zip && \
      unzip -q /var/tmp/agent.zip && rm /var/tmp/agent.zip && \
      echo "password" >/var/tmp/pw.txt  && chmod 0400 /var/tmp/pw.txt && \
      rm -rf /var/lib/apt/lists/*

# Format of agentadmin command:
# agentadmin --s "web-server configuration file, directory or site parameter" \
#                "OpenAM URL" "Agent URL" "realm" "agent user id" \
#                "path to the agent password file" [--changeOwner] [--acceptLicence] [--forceInstall]
#

# Because we are running this before OpenAM is up and running we need to use the forceinstall option.
# We are using some defaults here (OpenAM service name) that are not going to exist in most environments.
# They will need to be overridden at runtime by updating the bootstrap files.
# A possible option is to have Docker create a host entry for openam-svc - but that seems kludgy...
RUN /opt/web_agents/apache24_agent/bin/agentadmin --s /usr/local/apache2/conf/httpd.conf \
        "http://openam:80/openam" \
        "http://apache-svc:80/" \
        "/" \
        "apacheagent" \
        /var/tmp/pw.txt \
        --changeOwner --acceptLicence --forceInstall

# Cache size in bytes. The default is 1.5 GB. On Docker you need to run with --shm-size.
# Set this down lower for testing purposes.
ENV AM_MAX_SHARED_POOL_SIZE 1048576000

# todo: We should let above command create the conf file.
#COPY agent.conf /opt/web_agents/apache24_agent/instances/agent_1/config/agent.conf
COPY run.sh /var/tmp/

# Inherit CMD from Parent httpd:2.4
# CMD ["httpd-foreground"]

CMD ["/var/tmp/run.sh"]