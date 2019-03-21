FROM ubuntu:18.04
ARG  KUBE_LATEST_VERSION=v1.11.2
ARG  HELM_VERSION=v2.10.0

# Not used right now, but if we want this image to pull/push to a private repo, uncomment this and provide the secret:
# ENV GIT_SSH_COMMAND ssh -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i /etc/git-secret/ssh

WORKDIR /

RUN apt-get update \
  && apt-get install -y ca-certificates git vim bash curl openssh-client unzip python3-pip python3 openjdk-8-jdk \
  && pip3 install pytest allure-pytest pytest-html pytest-metadata requests beautifulsoup4 prettytable

ADD https://dl.bintray.com/qameta/maven/io/qameta/allure/allure-commandline/2.9.0/allure-commandline-2.9.0.zip /tmp
ADD https://storage.googleapis.com/kubernetes-helm/helm-${HELM_VERSION}-linux-amd64.tar.gz /tmp
ADD https://storage.googleapis.com/kubernetes-release/release/v1.11.2/bin/linux/amd64/kubectl /bin/
ADD https://raw.githubusercontent.com/ahmetb/kubectx/master/kubens /bin/
ADD https://raw.githubusercontent.com/ahmetb/kubectx/master/kubectx /bin/

RUN unzip /tmp/allure-commandline*.zip -d /tmp \
  && mkdir -p /opt/toolbox \
  && rm -rf /tmp/allure-commandline*.zip \
  && mv /tmp/allure-* /opt/toolbox

RUN tar -zxvf /tmp/helm*.tar.gz -C /tmp \
  && mv /tmp/linux-amd64/helm /bin/helm \
  && chmod +x  /bin/* \
  && rm -rf /tmp \
  && mkdir -p /opt/toolbox/bin \
  && git config --global user.email "forgeops-auto-export@forgerock.net" \
  && git config --global user.name "ForgeRock Auto export user" \
  && helm init --client-only

ADD *.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["pause"]
