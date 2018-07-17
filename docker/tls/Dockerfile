# TLS job image 
# Copyright (c) 2016-2018 ForgeRock AS.
#
# TLS job either creates an Self Signed certificate or adds imports user provided certificates
# based in selection in values files.  This job runs as part of the product Helm Charts.
FROM alpine:3.7

ENV NAMESPACE $NAMESPACE
ENV STRATEGY $STRATEGY

RUN apk update \
 && apk add --no-cache bash \
 && apk add --no-cache curl \
 && apk add --no-cache openssl

RUN curl -L https://storage.googleapis.com/kubernetes-release/release/v1.10.1/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl

RUN chmod +x /usr/local/bin/kubectl

COPY create_cert.sh .

COPY create_cert.sh /usr/local/bin/

RUN chmod 755 ./create_cert.sh

ENTRYPOINT ["./create_cert.sh"]