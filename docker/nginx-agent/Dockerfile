# Note: This is currently pending the fix for https://bugster.forgerock.org/jira/browse/AMAGENTS-501.
# Copyright (c) 2016-2017 ForgeRock AS.
FROM nginx:1.11.10

WORKDIR /opt

# Use this if you want to directly add the agent zip file.
#COPY agent.zip /var/tmp/agent.zip

# Waiting on https://bugster.forgerock.org/jira/browse/AMAGENTS-501 to fix:
# nginx: [emerg] module "/opt/web_agents/nginx12_agent/bin/../lib/openam_ngx_auth_module.so" version 1011010 instead of 1011013 in /etc/nginx/nginx.conf:8

# The agent bits are not on maven - so we need to download these from the internal build server.
# If you are outside of ForgeRock you will need to adjust for your environment, or just copy the agent.zip into this folder.
#ENV WEB_AGENT_BUILDS http://abondance-uk.internal.forgerock.com/public/webagents/engineering_master/Linux/

ARG AM_SERVER=http://openam.example.forgeops.com:80/openam
ARG AGENT_SERVER=http://apache-agent.example.forgeops.com
# For Local build - copy the .zip file in.
#COPY NGINX_r11303_Centos7_64bit_5.0.0-SNAPSHOT.zip /var/tmp/agent.zip



COPY nginx.conf /etc/nginx/
COPY default.conf /etc/nginx/conf.d/
COPY agent.zip /var/tmp/

RUN apt-get update && apt-get install --no-install-recommends  -y unzip curl vim openssl && \
      unzip -q /var/tmp/agent.zip && rm /var/tmp/agent.zip && \
      echo "password" >/var/tmp/pw.txt  && chmod 0400 /var/tmp/pw.txt && \
      rm -rf /var/lib/apt/lists/*

# Format of agentadmin command:
# agentadmin --s "web-server configuration file, directory or site parameter" \
#                "AM URL" "Agent URL" "realm" "agent user id" \
#                "path to the agent password file" [--changeOwner] [--acceptLicence] [--forceInstall]
#

# Because we are running this before AM is up and running we need to use the forceinstall option.
# We are using defaults here (AM service name) that are not going to exist in most environments.
# They will need to be overridden at runtime by updating the bootstrap files.
RUN /opt/web_agents/nginx12_agent/bin/agentadmin --s /etc/nginx/nginx.conf \
        "$AM_SERVER"  \
        "$AGENT_SERVER" \
        "/" \
        "apache" \
        /var/tmp/pw.txt \
        --changeOwner --acceptLicence --forceInstall

# Shared memory cache size in bytes. The default is 1.5 GB. On Docker you need to run with --shm-size.
# Set this down lower for testing purposes.
# 52428800 - 50 MB
ENV AM_MAX_SHARED_POOL_SIZE 52428800

WORKDIR /opt/web_agents
COPY *.sh /opt/web_agents/
COPY agent.conf /opt/web_agents/nginx12_agent/instances/agent_1/config/

# Copy testing pages to htdocs
COPY neu.html /usr/local/apache2/htdocs/
COPY policy.html /usr/local/apache2/htdocs/

RUN usermod -aG root nginx
RUN ln -sf /dev/stderr /opt/web_agents/nginx12_agent/instances/agent_1/logs/debug/debug.log



ENTRYPOINT ["/opt/web_agents/docker-entrypoint.sh"]

CMD ["/opt/web_agents/docker-entrypoint.sh"]
