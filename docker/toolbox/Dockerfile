FROM ubuntu:17.10

# If cloning from git..
ENV GIT_SSH_COMMAND ssh -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i /etc/git-secret/ssh

WORKDIR /

RUN apt-get update \
  && apt-get install -y ca-certificates git vim bash curl openssh-client 


ENV KUBE_LATEST_VERSION v1.7.5
ENV HELM_VERSION v2.6.1
ENV HELM_FILENAME helm-${HELM_VERSION}-linux-amd64.tar.gz

ADD http://storage.googleapis.com/kubernetes-helm/${HELM_FILENAME} /tmp
ADD https://storage.googleapis.com/kubernetes-release/release/${KUBE_LATEST_VERSION}/bin/linux/amd64/kubectl /bin/

RUN tar -zxvf /tmp/${HELM_FILENAME} -C /tmp \
  && mv /tmp/linux-amd64/helm /bin/helm \
  && chmod +x  /bin/kubectl \
  && rm -rf /tmp \
  && mkdir -p /opt/toolbox/bin \
  && git config --global user.email "forgeops-auto-export@forgerock.net" \
  && git config --global user.name "ForgeRock Auto export user"


WORKDIR /opt/toolbox

ADD bin /opt/toolbox/bin/
ADD *.sh /opt/toolbox/bin/
ADD templates /opt/toolbox/templates/

ENTRYPOINT ["/opt/toolbox/bin/docker-entrypoint.sh"]

CMD ["pause"]

