#Download Skaffold
FROM alpine as download-skaffold
ARG SKAFFOLD_VERSION=v1.17.2
ENV SKAFFOLD_URL https://storage.googleapis.com/skaffold/releases/${SKAFFOLD_VERSION}/skaffold-linux-amd64
RUN wget -O skaffold "${SKAFFOLD_URL}"
RUN chmod +x skaffold

# Download kustomize. The curl method below is the official / documented way of getting kustomize
FROM  curlimages/curl as download-kustomize
USER root
RUN apk add --no-cache bash
RUN curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash
RUN chmod +x kustomize


FROM gcr.io/cloud-builders/kubectl as runtime
ENV PATH=/builder/bin/:$PATH
ENV DOCKER_CONFIG=/builder/home/.docker
RUN mkdir -p /builder/bin && \
    apt-get update && \
    apt-get install --no-install-recommends --no-install-suggests -y \
    git python unzip && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean all

COPY --from=docker:18.09.6 /usr/local/bin/docker /usr/local/bin/
COPY --from=download-skaffold skaffold /builder/bin
COPY --from=download-kustomize kustomize /builder/bin
COPY skaffold.bash /builder/skaffold.bash
RUN chmod +700 /builder/skaffold.bash
ENTRYPOINT ["/builder/skaffold.bash"]



