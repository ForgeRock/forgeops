FROM gcr.io/forgerock-io/ds/pit1:latest AS ds
FROM openjdk:11-jdk-slim

ENV FORGEROCK_HOME /home/forgerock
RUN addgroup --gid 11111 forgerock && \
    adduser --shell /bin/bash --home "$FORGEROCK_HOME" --uid 11111 --disabled-password --ingroup root --gecos 'forgerock' forgerock && \
    chown -R forgerock:root  "$FORGEROCK_HOME"

WORKDIR /opt/gen

COPY --from=ds --chown=forgerock:root /opt/opendj /opt/gen/opendj
RUN apt-get update && apt-get install -y jq openssh-client openssl curl vim && \
    export KUBECTL_RELEASE=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt) && \
    curl -LO https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_RELEASE}/bin/linux/amd64/kubectl && \
    chmod +x ./kubectl && \
    mv ./kubectl /usr/local/bin/kubectl

ADD forgeops-secrets-image/ /opt/gen/
RUN mkdir -p /opt/gen/secrets/generic/truststore && \
    cp $JAVA_HOME/lib/security/cacerts /opt/gen/secrets/generic/truststore && \
    chmod 764 /opt/gen/secrets/generic/truststore/cacerts && \
    chown -R forgerock:root /opt/gen

# This speeds up secret generation on minikube by approx. 4x
ENV OPENDJ_JAVA_ARGS -Djava.security.egd=file:/dev/urandom

USER forgerock
CMD [ "/opt/gen/docker-entrypoint.sh" ]
