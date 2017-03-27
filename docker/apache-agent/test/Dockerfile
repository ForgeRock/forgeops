# Docker image for Apache + OpenAM HTTP agent.
FROM apache-agent-nightly

MAINTAINER warren.strange@forgerock.com

WORKDIR /opt

COPY agent.conf /opt/web_agents/apache24_agent/instances/agent_1/config/agent.conf

# Inherit CMD from Parent httpd:2.4 
# CMD ["httpd-foreground"]

