# Dockerfile that packages up Skaffold, Kustomize and kubectl to run under a CI/CD pipeline.
# Publish this to your registry and update your CI/CD pipelines to point at this image.
# See the tekton/ folder for an example of a CI/CD pipeline that deploys the ForgeRock Identity Platform.

# the sdk can install everythiung for us, use the smallest image
FROM gcr.io/google.com/cloudsdktool/cloud-sdk:alpine as base

FROM debian:bullseye-backports
ENV DOCKER_CONFIG=/builder/home/.docker
ENV PATH=/builder/google-cloud-sdk/bin:$PATH
RUN mkdir --mode=0766 -p /builder/bin

COPY --from=base /usr/local/bin/docker /usr/local/bin/
COPY --from=base /google-cloud-sdk /builder/google-cloud-sdk
COPY skaffold.bash /builder/skaffold.bash

RUN mkdir -p /builder/bin && \
    apt-get update && \
    apt-get install --no-install-recommends --no-install-suggests -y \
        openssh-client git python3 unzip curl wget ca-certificates jq && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean all

RUN /builder/google-cloud-sdk/install.sh --bash-completion=false --path-update=true --usage-reporting=false \
	--additional-components kubectl kustomize skaffold

RUN chmod +700 /builder/skaffold.bash
ENTRYPOINT ["/builder/skaffold.bash"]
