
FROM gcr.io/forgerock-io/ds-empty/pit1:latest AS ds
FROM openjdk:11-jdk-slim

WORKDIR /opt/gen
COPY --from=ds /opt/opendj /opt/gen/opendj
RUN apt-get update && apt-get install -y jq openssh-client openssl curl vim && \
    export KUBECTL_RELEASE=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt) && \
    curl -LO https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_RELEASE}/bin/linux/amd64/kubectl && \
    chmod +x ./kubectl && \
    mv ./kubectl /usr/local/bin/kubectl
ADD forgeops-secrets-image/ /opt/gen/
CMD [ "/opt/gen/docker-entrypoint.sh" ]