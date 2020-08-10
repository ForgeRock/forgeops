ARG VERSION=latest
ARG FORGEOPS_REGISTRY=gcr.io/engineering-devops
FROM ${FORGEOPS_REGISTRY}/yamkt:${VERSION}-skaffold as base
SHELL ["bash", "-c"]
RUN mkdir -p /opt/forgeops/{usr,mnt} \
        && mkdir 770 -p /opt/forgeops/mnt/{ctx,.pulumi} \
            && addgroup --gid 360360 cli \
                && chown -R root:cli /opt/forgeops/
RUN adduser --system --no-create-home --uid 501 --disabled-password --group forgeops \
            && usermod -a -G cli forgeops \
                && usermod -d /opt/forgeops/mnt forgeops \
                    && chown -R forgeops:forgeops /opt/forgeops/mnt \
                        && chmod 2775 /opt/forgeops
USER 501
RUN  docker-credential-gcloud config --token-source="env" && docker-credential-gcloud configure-docker
USER root
COPY docker/cli-tools/cdk/entrypoint.sh /opt/forgeops/usr/entrypoint.sh
ENTRYPOINT ["/opt/forgeops/usr/entrypoint.sh"]
WORKDIR /opt/forgeops/mnt/ctx
