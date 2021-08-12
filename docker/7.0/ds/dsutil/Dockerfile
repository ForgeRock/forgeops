# Utility ds image for testing, benchmarking, etc.
# Also useful as a general purpose debugging tool
FROM gcr.io/forgerock-io/ds:7.2.0-2021-5-05c258f2f9e13dca8feafaa6c6d4324f22b44dc8

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
