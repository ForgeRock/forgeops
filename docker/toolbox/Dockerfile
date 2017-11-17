FROM ubuntu:17.10

# If cloning from git..
ENV GIT_SSH_COMMAND ssh -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i /etc/git-secret/id_rsa


RUN apt-get update \
  && apt-get install -y ca-certificates git vim bash curl openssh-client bash-completion


ENV KUBE_LATEST_VERSION v1.8.3
ARG HELM_VERSION=v2.7.0
ARG HELM_FILENAME=helm-${HELM_VERSION}-linux-amd64.tar.gz
ENV TOOLBOX_DIR /opt/forgerock

WORKDIR /tmp

# See https://github.com/moby/moby/issues/33849. Until GKE upgrades to >17.06, we need to use wget
#ADD https://storage.googleapis.com/kubernetes-helm/${HELM_FILENAME} /tmp/
ADD https://storage.googleapis.com/kubernetes-release/release/${KUBE_LATEST_VERSION}/bin/linux/amd64/kubectl /bin/

RUN curl -O https://storage.googleapis.com/kubernetes-helm/${HELM_FILENAME}

RUN tar xvfz ${HELM_FILENAME} && mv linux-amd64/helm /bin/helm \
  && chmod +x  /bin/kubectl \
  && mkdir -p ${TOOLBOX_DIR}/bin \
  && git config --global user.email "forgeops-auto-export@forgerock.net" \
  && git config --global user.name "ForgeRock Auto export user" \
  && helm init --client-only \
  && helm repo add forgerock https://storage.googleapis.com/forgerock-charts \
  && printf "source /etc/bash_completion; source <(kubectl completion bash)\n" >> $HOME/.bashrc \
  && printf "source <(helm completion bash); alias k=kubectl; alias h=helm" >> $HOME/.bashrc



WORKDIR ${TOOLBOX_DIR}

ADD bin ${TOOLBOX_DIR}/bin/
ADD *.sh ${TOOLBOX_DIR}/bin/



ENTRYPOINT ["/opt/forgerock/bin/docker-entrypoint.sh"]

CMD ["bootstrap"]

