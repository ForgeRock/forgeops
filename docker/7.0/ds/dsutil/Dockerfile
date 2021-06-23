# Utility ds image for testing, benchmarking, etc.
# Also useful as a general purpose debugging tool
FROM gcr.io/forgerock-io/ds/pit1:7.2.0-4ab3232b162333ee055c3ed777d84ef6d3350786

USER root
ENV DEBIAN_FRONTEND=noninteractive
ENV APT_OPTS="--no-install-recommends --yes"
RUN apt-get update \
        && apt-get install -y bash vim curl dnsutils procps netcat wget \
        && apt-get clean \
        && rm -r /var/lib/apt/lists /var/cache/apt/archives


COPY --chown=forgerock:root bin/*  bin/
COPY --chown=forgerock:root ds-idrepo.template config/MakeLDIF

# reset entrypoint of ds container
ENTRYPOINT []
CMD ["bash"]
