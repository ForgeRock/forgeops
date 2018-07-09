# Copyright (c) 2016-2018 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file
# Nginx agent base image
FROM nginx:1.11.10

WORKDIR /opt

ARG AM_SERVER=http://openam.example.forgeops.com:80/openam
ARG AGENT_SERVER=http://apache-agent.example.forgeops.com

# Copy nginx.conf with included agent module
COPY nginx.conf /etc/nginx/
COPY default.conf /etc/nginx/conf.d/
COPY agent.zip /var/tmp/

# Install necessary dependencies
RUN apt-get update && apt-get install --no-install-recommends  -y unzip curl vim openssl && \
      unzip -q /var/tmp/agent.zip && rm /var/tmp/agent.zip && \
      echo "password" >/var/tmp/pw.txt  && chmod 0400 /var/tmp/pw.txt && \
      rm -rf /var/lib/apt/lists/*

# Because we are running this before AM is up and running we need to use the forceinstall option.
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

# Copy testing pages to htdocs
COPY neu.html /usr/share/nginx/html/
COPY policy.html /usr/share/nginx/html/

RUN chown -R nginx:nginx /opt/

ENTRYPOINT ["/opt/web_agents/docker-entrypoint.sh"]
CMD ["/opt/web_agents/docker-entrypoint.sh"]
