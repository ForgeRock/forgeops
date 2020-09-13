# Utility ds image for testing, benchmarking, etc.
# Also useful as a general purpose debugging tool
FROM gcr.io/forgerock-io/ds:7.1.0-3d09928ea2dad1535829a54bcd97ea600c3f693f

USER root
RUN apt-get update && apt-get install -y bash vim curl dnsutils procps netcat


COPY --chown=forgerock:root bin/*  bin/

# reset entrypoint of ds container
ENTRYPOINT []
CMD ["bash"]
