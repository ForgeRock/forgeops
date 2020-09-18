ARG VERSION=latest
ARG FORGEOPS_REGISTRY=gcr.io/engineering-devops
FROM ${FORGEOPS_REGISTRY}/yamkt:${VERSION}-skaffold as tools
FROM debian:sid-slim
SHELL ["bash", "-c"]
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -y \
        && apt-get install --yes --no-install-recommends \
                           make \
                           git \
                           python3-minimal \
                           python3-pip \
                           python3-setuptools

COPY docker/cli-tools/repo/src /opt/workspace
COPY --from=tools ["/usr/local/bin/skaffold","/usr/local/bin/kustomize","/usr/local/bin/docker-credential-gcloud", "/usr/local/bin/kubectl", "/usr/local/bin/"]

RUN cd /opt/workspace && pip3 install . && docker-credential-gcloud config
WORKDIR /opt/workspace
