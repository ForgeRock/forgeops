# Git image for performing configuration checkout / push.
FROM alpine:3.7

ENV FORGEROCK_HOME /opt/forgerock

RUN apk add --no-cache git bash vim openssh-client \
    && mkdir -p /opt/forgerock \
    && addgroup -g 11111 forgerock \
    && adduser -s /bin/bash -h "$FORGEROCK_HOME" -u 11111 -D -G forgerock forgerock \
    && chown -R forgerock /opt \
    && git config --global user.email "auto-sync@forgerock.net"  \
    && git config --global user.name "Git Auto-sync user"

# GIT_ROOT is where git config is cloned to. Don't change this unless you know what you are doing.
ENV GIT_ROOT /git/config
# The ssh command to use for authenticated git operations.
ENV GIT_SSH_COMMAND ssh -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i /etc/git-secret/id_rsa

COPY *.sh  /

USER forgerock

# Add ssh keys
RUN mkdir -p /opt/forgerock/.ssh  && \
    ssh-keyscan github.com >> ~/.ssh/known_hosts



CMD ["init"]

ENTRYPOINT ["/docker-entrypoint.sh"]

