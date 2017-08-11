FROM alpine:3.6

ENV FORGEROCK_HOME /opt/forgerock

RUN apk add --no-cache git bash vim openssh-client \
    && mkdir -p /opt/forgerock \
    && addgroup -g 11111 forgerock \
    && adduser -s /bin/bash -h "$FORGEROCK_HOME" -u 11111 -D -G forgerock forgerock \
    && chown -R forgerock /opt \
    && git config --global user.email "auto-sync@forgerock.net"  \
    && git config --global user.name "Git Auto-sync user"

ENV GIT_SSH_COMMAND ssh -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i /etc/git-secret/ssh

ADD *.sh  /

USER forgerock

CMD ["init"]

ENTRYPOINT ["/docker-entrypoint.sh"]

