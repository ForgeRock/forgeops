# Copyright (c) 2016-2019 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file
# Nginx agent base image
FROM forgerock/downloader

RUN download nginx-agent
RUN unzip nginx-agent.zip -d /var/tmp

FROM nginx:1.11.10

COPY --from=0 /var/tmp/web_agents /opt/web_agents

WORKDIR /opt

ARG AM_SERVER=http://login.example.forgeops.com:80/openam
ARG AGENT_SERVER=http://apache-agent.example.forgeops.com

# Copy nginx.conf with included agent module
COPY nginx.conf /etc/nginx/
COPY default.conf /etc/nginx/conf.d/

RUN echo "deb [check-valid-until=no] http://cdn-fastly.deb.debian.org/debian jessie main" > /etc/apt/sources.list.d/jessie.list
RUN echo "deb [check-valid-until=no] http://archive.debian.org/debian jessie-backports main" > /etc/apt/sources.list.d/jessie-backports.list
RUN sed -i '/deb http:\/\/deb.debian.org\/debian jessie-updates main/d' /etc/apt/sources.list
RUN apt-get -o Acquire::Check-Valid-Until=false update

# Install necessary dependencies
RUN apt-get install --no-install-recommends  -y unzip curl vim openssl && \
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
