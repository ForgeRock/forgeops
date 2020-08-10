ARG VERSION=latest
FROM gcr.io/google-containers/pause:latest
ARG FORGEOPS_REGISTRY=gcr.io/engineering-devops    
FROM ${FORGEOPS_REGISTRY}/yamkt:$VERSION as finale 
FROM debian:sid-slim
ENV DEBIAN_FRONTEND=noninteractive
COPY --from=0 /pause /usr/local/bin/pause                   
COPY --from=1 /usr/local/bin/kubectl /usr/local/bin/kubectl 
RUN apt-get update -y \
        && apt-get install --no-install-recommends -y curl \
                              dnsutils \
                              jq \
                              vim \
                              tmux \
                              ldap-utils \
                              strace \
                              nmap \
                              netcat


CMD ["/usr/local/bin/pause"]
