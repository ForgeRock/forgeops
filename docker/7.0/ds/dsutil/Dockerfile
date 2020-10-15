# Utility ds image for testing, benchmarking, etc.
# Also useful as a general purpose debugging tool
FROM gcr.io/forgerock-io/ds:7.1.0-52dd7c2c1d90f7bad8515c5f2187182c74cd3682

USER root
RUN apt-get update && apt-get install -y bash vim curl dnsutils procps netcat


COPY --chown=forgerock:root bin/*  bin/
COPY --chown=forgerock:root ds-idrepo.template config/MakeLDIF

# reset entrypoint of ds container
ENTRYPOINT []
CMD ["bash"]
