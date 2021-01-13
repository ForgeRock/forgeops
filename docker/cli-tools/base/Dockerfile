ARG FORGEOPS_REGISTRY=gcr.io/engineering-devops
ARG SKAFF_VERSION=v1.17.2
ARG KUSTOMIZE_VERSION=v3.9.1
ARG KUBECTL_VERSION=v1.20.2
ARG KUBECTX_VERSION=v0.9.1
ARG AWSCLI_VERSION=1.18.215
ARG CLOUD_SDK_VERSION=323.0.0
ARG AZURE_VERSION=2.8.0
FROM debian:buster-slim as base
RUN apt-get update -y \
        && apt-get install -y --no-install-recommends util-linux ca-certificates \
            && apt-get clean \
                && apt-get autoremove --purge  \
                    && rm -rf /var/lib/apt/lists/*

FROM debian:buster as builder
SHELL ["bash", "-c"]
ENV DEBIAN_FRONTEND=noninteractive
RUN mkdir -p /opt/build/bin
RUN apt-get update --yes \
        && apt-get install --yes --no-install-recommends ca-certificates \
                                                         curl \
                                                         apt-transport-https \
                                                         xz-utils \
                                                         python \
                                                         python-pip \
                                                         python-setuptools \
                                                         python-virtualenv \
                                                         python-dev \
                                                         libpython-dev \
                                                         libxml2-dev \
                                                         libxslt1-dev \
                                                         build-essential \
                                                         autoconf \
                                                         libssl-dev \
                                                         libffi-dev \
            && apt-get clean \
                && apt-get autoremove --purge  \
                    && rm -rf /var/lib/apt/lists/*


FROM builder as kubectl
ARG KUBECTL_VERSION
RUN curl -L "https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" -o /opt/build/kubectl \
        && install /opt/build/kubectl /opt/build/bin/kubectl

FROM builder as awscli
ARG AWSCLI_VERSION
RUN mkdir -p /opt/build/awswheelhouse \
        && pip2 install wheel \
            && pip2 wheel -w /opt/build/awswheelhouse "awscli==${AWSCLI_VERSION}"

FROM builder as cloud-sdk
ARG CLOUD_SDK_VERSION
RUN curl "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-x86_64.tar.gz" -o /opt/build/google.tar.gz

FROM builder as azcli
ARG AZURE_VERSION
RUN mkdir -p /opt/build/azwheelhouse \
        && pip2 install wheel \
            && pip2 wheel -w /opt/build/azwheelhouse "azure-cli==${AZURE_VERSION}"

FROM builder as kustomize
ARG KUSTOMIZE_VERSION
RUN curl -sL https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize/${KUSTOMIZE_VERSION}/kustomize_${KUSTOMIZE_VERSION}_linux_amd64.tar.gz -o /tmp/kustomize.tar.gz \
        && tar -xvf /tmp/kustomize.tar.gz -C /tmp \
            && install /tmp/kustomize /opt/build/bin/kustomize

FROM gcr.io/k8s-skaffold/skaffold:${SKAFF_VERSION} as skaffold-base

FROM builder as kubectx
ARG KUBECTX_VERSION
RUN curl -sL https://codeload.github.com/ahmetb/kubectx/tar.gz/${KUBECTX_VERSION} -o /tmp/kubectx.tar.gz \
        && mkdir /tmp/kubectx \
            && tar -xvf /tmp/kubectx.tar.gz -C /tmp/kubectx --strip-components=1 \
                && install /tmp/kubectx/kubens /opt/build/bin/kubens \
                    && install /tmp/kubectx/kubectx /opt/build/bin/kubectx

FROM base as finale
LABEL maintainer="cloud_eng_team@forgerock.com"
SHELL ["bash", "-c"]
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -y \
        && apt-get install -y --no-install-recommends ca-certificates \
                                                      python-minimal \
                                                      python-pip \
                                                      python-setuptools \
                                                      jq \
            && apt-get clean \
                && apt-get autoremove --purge  \
                    && rm -rf /var/lib/apt/lists/*

COPY --from=kubectl /opt/build/bin/* /usr/local/bin/
COPY --from=awscli /opt/build/awswheelhouse/* /tmp/awswheelhouse/
COPY --from=cloud-sdk /opt/build/google.tar.gz /tmp/google.tar.gz
COPY --from=azcli /opt/build/azwheelhouse/* /tmp/azwheelhouse/
COPY --from=kustomize /opt/build/bin/* /usr/local/bin/
COPY --from=kubectx /opt/build/bin/* /usr/local/bin/
COPY --from=skaffold-base /usr/bin/skaffold /usr/local/bin/

RUN pip2 install --no-index --find-links /tmp/awswheelhouse awscli && rm -r /tmp/awswheelhouse
RUN pip2 install --no-index --find-links /tmp/azwheelhouse azure-cli && rm -r /tmp/azwheelhouse

RUN tar -xvf /tmp/google.tar.gz -C /usr/local/ \
        && /usr/local/google-cloud-sdk/install.sh --quiet --path-update=true
