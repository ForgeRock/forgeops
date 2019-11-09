FROM gcr.io/engineering-devops/pulumi-nodejs:latest as base
RUN adduser --home /opt/forgeops --disabled-password --gecos "" forgeops \
        && mkdir -p /opt/forgeops/usr \
            && addgroup --gid 360360 cli \
                && usermod -a -G cli forgeops \
                    && chown -R root:cli /opt/forgeops/
COPY --chown=0:360360 cluster/pulumi /opt/forgeops/usr/
RUN cd /opt/forgeops/usr/ \
        && npm --loglevel=error ci --production \
            && helm --home /opt/forgeops/.helm init --client-only

FROM base as finale
COPY --chown=0:360360 docker/cli-tools/entrypoint.sh /opt/forgeops/usr/entrypoint.sh
ENTRYPOINT ["/opt/forgeops/usr/entrypoint.sh"]
WORKDIR /opt/forgeops/local
