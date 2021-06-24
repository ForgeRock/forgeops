# Utility ds image for testing, benchmarking, etc.
# Also useful as a general purpose debugging tool
FROM gcr.io/forgerock-io/ds/pit1:7.1.1-dc08809f5ffebd54c5e654ff3d3fb55f32b0ba58

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
