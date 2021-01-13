ARG VERSION=latest
ARG FORGEOPS_REGISTRY=gcr.io/engineering-devops
FROM gcr.io/google-containers/pause:latest as pause

ARG VERSION=latest
ARG FORGEOPS_REGISTRY=gcr.io/engineering-devops
FROM $FORGEOPS_REGISTRY/cli-tools/base:$VERSION
ARG VSCODE_CONTAINERS="https://raw.githubusercontent.com/microsoft/vscode-dev-containers/master/script-library/common-debian.sh"
ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-c"]

RUN useradd forgeops --home /opt/workspace --gid 0 \
        && apt-get update \
        && apt-get install -y curl ca-certificates --no-install-recommends \
        && mkdir -m 0770 -p /opt/{workspace,build} \
        && chown forgeops:root /opt/{workspace,build} \
        && curl -Lso common.sh ${VSCODE_CONTAINERS} \
        && bash common.sh false none automatic automatic false false

COPY --from=pause /pause /usr/local/bin/pause

RUN mkdir -p /opt/build/.local/bin \
        && mkdir -p /opt/build/.vim/pack/plugins/start \
        && git clone --depth 1 https://github.com/dense-analysis/ale.git /opt/build/.vim/pack/plugins/start/ale \
        && git clone --depth 1 https://github.com/preservim/nerdtree.git /opt/build/.vim/pack/plugins/start/nerdtree \
        && chown -R forgeops:root /opt/

USER forgeops

RUN echo "PATH=/opt/workspace/bin:$PATH" >> /opt/build/.bashrc \
        && echo "bash -c /opt/build/bin/start-shell.sh" >> /opt/build/.bashrc

COPY --chown=forgeops:root etc /opt/build/etc
COPY --chown=forgeops:root bin/  /opt/build/bin
COPY --chown=forgeops:root bin/git-set-fork.sh /usr/local/bin

ENV SSH_PORT=4222
ENV WORKSPACE=/opt/workspace
WORKDIR /opt/workspace
ENTRYPOINT ["/opt/build/bin/entrypoint.sh"]
CMD ["/usr/local/bin/pause"]
