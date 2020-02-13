FROM gcr.io/google-containers/pause:latest as pause

FROM gcr.io/engineering-devops/yamkt:latest-skaffold as base
ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-c"]

RUN adduser --disabled-password forgeops \
        && mkdir -m 0770 -p /opt/workspace \
            && chown root:forgeops /opt/workspace
COPY --from=pause /pause /usr/local/bin/pause
RUN apt-get update && apt-get install --yes vim jq curl dnsutils tmux git

USER forgeops
COPY --chown=forgeops:forgeops docker/cli-tools/toolbox/etc /home/forgeops/.etc
COPY --chown=forgeops:forgeops docker/cli-tools/toolbox/bin/ /home/forgeops/.local/bin/

RUN mkdir -p /home/forgeops/.local/bin \
        && mkdir -p ~/.vim/pack/plugins/start \
            && git clone --depth 1 https://github.com/dense-analysis/ale.git ~/.vim/pack/plugins/start/ale \
                && git clone --depth 1 https://github.com/preservim/nerdtree.git ~/.vim/pack/plugins/start/nerdtree
COPY bin/ /home/forgeops/.local/bin
RUN echo "PATH=~/.local/bin:$PATH" >> ~/.bashrc \
        && echo "bash -c ~/.local/bin/start-shell.sh" >> ~/.bashrc

ENV WORKSPACE=/opt/workspace/forgeops
WORKDIR /opt/workspace
ENTRYPOINT ["/home/forgeops/.local/bin/entrypoint.sh"]
CMD ["/usr/local/bin/pause"]
