# Utility image 
# Copyright (c) 2016-2018 ForgeRock AS.
#
# Utility shell scripts used as init containers to perform creation of bootstrap files
# wait for for pods to be available, etc.
# We expect this to be deprecated for 6.5 
FROM alpine:3.7

#  -Dcom.iplanet.services.debug.level=error

ENV FORGEROCK_HOME /home/forgerock

ENV KUBE_LATEST_VERSION="v1.10.1"

RUN apk add --update ca-certificates \
 && apk add --update -t deps curl\
 && curl -L https://storage.googleapis.com/kubernetes-release/release/${KUBE_LATEST_VERSION}/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl \
 && chmod +x /usr/local/bin/kubectl \
 && apk del --purge deps \
 && apk add --update jq su-exec unzip curl bash openldap-clients \
 && rm /var/cache/apk/* \
 && mkdir -p $FORGEROCK_HOME \
 && addgroup -g 11111 forgerock \
 && adduser -s /bin/bash -h "$FORGEROCK_HOME" -u 11111 -D -G forgerock forgerock


# # openldap-clients is needed to test for the configuration store.
# RUN apk add --no-cache su-exec unzip curl bash openldap-clients \
#     && mkdir -p $FORGEROCK_HOME \
#     && addgroup -g 11111 forgerock \
#     && adduser -s /bin/bash -h "$FORGEROCK_HOME" -u 11111 -D -G forgerock forgerock

USER forgerock


COPY *.sh $FORGEROCK_HOME/

ENTRYPOINT ["/home/forgerock/docker-entrypoint.sh"]


CMD ["pause"]