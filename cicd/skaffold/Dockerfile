# Dockerfile that packages up Skaffold, Kustomize and kubectl to run under a CI/CD pipeline.
# Publish this to your registry and update your CI/CD pipelines to point at this image.
# See the tekton/ folder for an example of a CI/CD pipeline that deploys the ForgeRock Identity Platform.

# the sdk can install everythiung for us, use the smallest image
ARG KUSTOMIZE_VERSION=v4.4.1
ARG KUBECTL_VERSION=v1.21.2
ARG SKAFFOLD_VERSION=v1.35.1

FROM gcr.io/google.com/cloudsdktool/cloud-sdk:alpine as base
ARG SKAFFOLD_VERSION
FROM gcr.io/k8s-skaffold/skaffold:${SKAFFOLD_VERSION} as skaffold


FROM debian:bullseye-backports
ARG KUSTOMIZE_VERSION
ARG KUBECTL_VERSION
ENV DOCKER_CONFIG=/builder/home/.docker
ENV PATH=/builder/google-cloud-sdk/bin:$PATH
RUN mkdir --mode=0766 -p /builder/bin

COPY --from=base /usr/local/bin/docker /usr/local/bin/
COPY --from=base /google-cloud-sdk /builder/google-cloud-sdk
COPY --from=skaffold /usr/bin/skaffold /usr/local/bin/skaffold
COPY skaffold.bash /builder/skaffold.bash

RUN mkdir -p /builder/bin && \
    apt-get update && \
    apt-get install --no-install-recommends --no-install-suggests -y \
        openssh-client git python3 python3-setuptools unzip curl wget ca-certificates jq && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean all

RUN /builder/google-cloud-sdk/install.sh --bash-completion=false --path-update=true --usage-reporting=false
# Install kubectl
RUN curl -L "https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" -o /tmp/kubectl \
                && install /tmp/kubectl /usr/local/bin/kubectl
# Install kustomize
RUN curl -sL https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize/${KUSTOMIZE_VERSION}/kustomize_${KUSTOMIZE_VERSION}_linux_amd64.tar.gz -o /tmp/kustomize.tar.gz \
        && tar -xvf /tmp/kustomize.tar.gz -C /tmp \
            && install /tmp/kustomize /usr/local/bin/kustomize

RUN chmod +700 /builder/skaffold.bash
ENTRYPOINT ["/builder/skaffold.bash"]
