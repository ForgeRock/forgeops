FROM gcr.io/google-containers/pause:latest as pause

FROM gcr.io/engineering-devops/yamkt:latest-skaffold as base
ARG COMMON_SCRIPT_SOURCE="https://raw.githubusercontent.com/microsoft/vscode-dev-containers/master/script-library/common-debian.sh"
ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-c"]

RUN adduser --disabled-password forgeops --no-create-home --home /opt/workspace \
        && mkdir -m 0770 -p /opt/{workspace,build} \
        && chown root:forgeops /opt/{workspace,build}
COPY --from=pause /pause /usr/local/bin/pause
RUN apt-get update && apt-get install --yes vim jq curl dnsutils tmux git rsync openssh-server



USER forgeops
COPY --chown=forgeops:forgeops docker/cli-tools/toolbox/etc /opt/build/.etc
COPY --chown=forgeops:forgeops docker/cli-tools/toolbox/bin/  /opt/build/.local/bin/

RUN mkdir -p /opt/build/.local/bin \
        && mkdir -p /opt/build/.vim/pack/plugins/start \
        && git clone --depth 1 https://github.com/dense-analysis/ale.git /opt/build/.vim/pack/plugins/start/ale \
        && git clone --depth 1 https://github.com/preservim/nerdtree.git /opt/build/.vim/pack/plugins/start/nerdtree \
                && mkdir -p /opt/build/etc/ssh \
                    && ssh-keygen -t rsa -f /opt/build/etc/ssh_host_rsa_key -N '' \
                        && cp /etc/ssh/sshd_config /opt/build/etc/sshd_config  \
                            && sed -i "s@UsePAM yes@UsePAM no@g" /opt/build/etc/sshd_config \
                                && sed -i "s@#HostKey /etc/ssh/ssh_host_rsa_key@HostKey /opt/workspace/etc/ssh_host_rsa_key@g" /opt/build/etc/sshd_config \
                                    && echo "AllowUsers forgeops" >> /opt/build/etc/sshd_config \
                                    && echo "PermitUserEnvironment yes" >> /opt/build/etc/sshd_config \
                                        && mkdir -p /opt/build/.ssh \
                                            && chmod -R 0700 /opt/build/.ssh

COPY bin/ /opt/build/.local/bin

COPY config /opt/build/.ssh/config

RUN echo "PATH=~/.local/bin:$PATH" >> /opt/build/.bashrc \
        && echo "bash -c ~/.local/bin/start-shell.sh" >> /opt/build/.bashrc

ENV SSH_PORT=4222
ENV WORKSPACE=/opt/workspace/forgeops
WORKDIR /opt/workspace
ENTRYPOINT ["/opt/build/.local/bin/entrypoint.sh"]
CMD ["/usr/local/bin/pause"]
