FROM ubuntu:16.04

ENV KUBE_LATEST_VERSION v1.6.1
ENV HELM_VERSION v2.2.3
ENV HELM_FILENAME helm-${HELM_VERSION}-linux-amd64.tar.gz

WORKDIR /

RUN apt-get update \
  && apt-get install -y ca-certificates git vim bash curl openssh-client

ADD http://storage.googleapis.com/kubernetes-helm/${HELM_FILENAME} /tmp
ADD https://storage.googleapis.com/kubernetes-release/release/${KUBE_LATEST_VERSION}/bin/linux/amd64/kubectl /usr/local/bin/

RUN tar -zxvf /tmp/${HELM_FILENAME} -C /tmp \
  && mv /tmp/linux-amd64/helm /bin/helm \
  && chmod +x  /usr/local/bin/kubectl \
  && rm -rf /tmp

#ADD fretes /fretes
#ADD *.sh /fretes/
#ADD custom.yaml /fretes/helm/
#ADD README.md /fretes
#
#WORKDIR /fretes
#
#ENTRYPOINT ["/fretes/docker-entrypoint.sh"]
CMD [ "setup"]