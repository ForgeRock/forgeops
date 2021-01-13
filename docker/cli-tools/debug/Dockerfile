ARG VERSION=latest
ARG FORGEOPS_REGISTRY=gcr.io/engineering-devops
FROM gcr.io/google-containers/pause:latest

ARG FORGEOPS_REGISTRY=gcr.io/engineering-devops
ARG VERSION=latest
FROM $FORGEOPS_REGISTRY/base:$VERSION

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
                              ncat \
                              hping3


CMD ["/usr/local/bin/pause"]
