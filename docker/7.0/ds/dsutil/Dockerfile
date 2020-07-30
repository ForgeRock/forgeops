# Utility ds image for testing, benchmarking, etc.
FROM gcr.io/forgerock-io/ds/pit1:7.0.0-8d1a3ea294f88f2a973a47d5c6978a0f5ec807bb

USER root
RUN apt-get update && apt-get install -y vim
USER forgerock


COPY --chown=forgerock:root bin/*  bin/


ENTRYPOINT ["bash"]
# Just sleep a long time waiting for someone to exec into the pod
CMD [ "-c", "trap : TERM INT; sleep infinity & wait" ]
