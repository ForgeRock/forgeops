FROM debian:buster as builder

RUN apt-get update \
        && apt-get install -y curl ca-certificates bash --no-install-recommends

ARG KUSTOMIZE_VERSION=latest
ARG KUBECTL_VERSION=latest

RUN mkdir -p /opt/bin \
        && curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
        && cp kubectl /opt/bin  \
        && curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash \
        && cp kustomize /opt/bin \
        && chmod a+rx /opt/bin/*

# Skaffold
RUN curl -Lo skaffold https://storage.googleapis.com/skaffold/releases/latest/skaffold-linux-amd64 \
        && chmod +x skaffold && mv skaffold /opt/bin

# TODO: Pull the forgeops cli
#  RUN curl -LO https://github.com/ForgeRock/forgeops-cli/releases/latest/download/todo \
#         && tar xvfz

FROM debian:buster
ARG VSCODE_CONTAINERS="https://raw.githubusercontent.com/microsoft/vscode-dev-containers/master/script-library/common-debian.sh"
ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-c"]

RUN useradd forgerock --home /opt/workspace --gid 0 \
        && apt-get update \
        && apt-get install -y curl ca-certificates vim bash procps git netcat dnsutils tmux ldap-utils  \
        && mkdir -m 0770 -p /opt/{workspace,build} \
        && chown forgerock:root /opt/{workspace,build}

# Uncomment for vscode support
# RUN curl -Lso common.sh ${VSCODE_CONTAINERS} \
#         && bash common.sh false none automatic automatic false false

USER forgerock

RUN echo "PATH=/opt/workspace/bin:$PATH" >> /opt/build/.bashrc \
        && echo "bash -c /opt/build/bin/start-shell.sh" >> /opt/build/.bashrc

COPY --from=gcr.io/google-containers/pause:latest /pause /usr/local/bin/pause
COPY --from=builder /opt/bin/* /usr/local/bin/
COPY --chown=forgerock:root etc /opt/build/etc
COPY --chown=forgerock:root bin/  /opt/build/bin
COPY --chown=forgerock:root bin/git-set-fork.sh /usr/local/bin

ENV SSH_PORT=4222
ENV WORKSPACE=/opt/workspace

ENV PATH=/opt/build/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/workspace/forgeops/bin

WORKDIR /opt/workspace
ENTRYPOINT ["/opt/build/bin/entrypoint.sh"]
CMD ["/usr/local/bin/pause"]
