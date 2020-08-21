ARG VERSION=latest
ARG FORGEOPS_REGISTRY=gcr.io/engineering-devops
FROM $FORGEOPS_REGISTRY/yamkt:$VERSION as base
ENV HELM_HOME=/opt/forgeops/usr/helm

SHELL ["bash", "-c"]
ENV PULUMI_SKIP_UPDATE_CHECK=1

RUN mkdir -p /opt/forgeops/ \
        && addgroup --gid 360360 cli \
                    && chown -R root:cli /opt/forgeops/

COPY --chown=0:360360 cluster/pulumi /opt/forgeops/usr/
RUN chmod 2775 /opt/forgeops \
        && cd /opt/forgeops/usr/ \
            && PULUMI_HOME=/tmp/pulumi npm --loglevel=error ci --production \
                && install --backup=numbered -g 360360 /tmp/pulumi/plugins/**/* /opt/forgeops/usr/bin \
                    && rm -rf /tmp/pulumi \
                        && chown -R root:cli /opt/forgeops/usr/node_modules

RUN helm repo add stable https://kubernetes-charts.storage.googleapis.com

ARG VERSION=latest
ARG FORGEOPS_REGISTRY=gcr.io/engineering-devops  
FROM ${FORGEOPS_REGISTRY}/yamkt:${VERSION} as finale
ENV NODE_PATH=/opt/forgeops/usr/node_modules
ENV PULUMI_SKIP_UPDATE_CHECK=1
ENV HELM_HOME=/opt/forgeops/usr/helm
ENV PS1="forgeopscli▶ "
ENV PATH="$PATH:/usr/local/google-cloud-sdk/bin:/opt/forgeops/usr/bin"

COPY --from=base /opt /opt

RUN  adduser --system --no-create-home --uid 501 --disabled-password --group forgeops \
        && addgroup --gid 360360 cli \
            && usermod -a -G cli forgeops \
                && usermod -d /opt/forgeops/mnt forgeops \
                    && mkdir --mode 770 -p /opt/forgeops/mnt/{ctx,.pulumi} \
                        && chown -R forgeops:forgeops /opt/forgeops/mnt

COPY --chown=0:360360 docker/cli-tools/cdm/entrypoint.sh /opt/forgeops/usr/entrypoint.sh
COPY --chown=0:360360 bin/ /opt/forgeops/usr/bin
COPY --chown=0:360360 cluster/addons /opt/forgeops/usr/addons
ENV ADDONS_BASE=/opt/forgeops/usr/addons

ENTRYPOINT ["/opt/forgeops/usr/entrypoint.sh"]
WORKDIR /opt/forgeops/mnt/ctx
