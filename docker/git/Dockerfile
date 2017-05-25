FROM alpine:3.5

RUN apk add --no-cache git bash vim openssh-client && \
    git config --global user.email "auto-sync@forgerock.net" && \
    git config --global user.name "Git Auto-sync user"

ADD *.sh  / 

CMD ["init"]

ENTRYPOINT ["/docker-entrypoint.sh"]

